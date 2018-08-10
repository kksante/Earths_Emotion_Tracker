from pyspark import SparkContext
from metadata_dict import country_names, event_names, event_cause
from operator import itemgetter
import pyspark_cassandra

# sqlContext = SQLContext(sc)
sc = SparkContext()
data = sc.textFile("s3a://kv-data/old/*")
# data = sc.textFile("s3a://gdelt-open-data/events/*")
# data = sc.textFile("s3a://gdelt-open-data/events/*")
rdd = data.map(lambda x: x.encode("utf", "ignore"))

data.cache()

def process_data(rdd, time_period):

    def ingest_data(rdd, period):
        if period == "daily":
            time = 1
        elif period == "monthly":
            time = 2
        else:
            time = 3

        # column indices for required data fields
        event_id = 0
        event_code_1 = 12
        event_code_2 = 22
        cameo_code = 26
        actor1_geotype = 35
        event_base_code = 27
        event_root_cause = 28
        quad_class = 29
        article_count = 33
        gold_scale = 30
        article_tone = 34
        country_code = 51

        data = rdd.map(lambda x: x.split('\t')) \
                      .map(lambda x: ((x[event_id],
                                       x[country_code],
                                        x[time],
                                        x[event_code_1],
                                        x[event_code_2],
                                        x[event_root_cause],
                                        x[article_count],
                                        x[gold_scale],
                                        x[article_tone]
                                      )))
        return data

    def valid_record(record):
        try:
            if record[1].strip() == "":
                raise Exception("missing keys")

            if record[2].strip() == "":
                raise Exception("missing date")

            if record[3].strip() == "" and record[4].strip() == "":
                raise Exception("missing event info")

            if record[5].strip() == "":
                raise Exception("missing root cause")

            if record[6].strip() == "" or record[7].strip() == "" or record[8].strip() == "":
                raise Exception("missing root cause")

            int(record[2])
            int(record[6])
            float(record[7])
            float(record[8])
            return True

        except Exception:
            return False

    def get_event_code(record):
        if record[2] == "" and record[3] != "":
            return (record[0], record[1], record[3], record[4], record[5], record[6], record[7])
        else:
            return (record[0], record[1], record[2], record[4], record[5], record[6], record[7])

    def add_event_info(record):
        event_type = record[1]
        mentions = 0

        for item in event_type:
            mentions += item[1]

        return ((record[0], event_type, record[2], mentions))

    def add_top_events(record):
        event_list = record[1]
        events = record[2]
        event_dict = {}

        for item in event_list:
            event_type = item[0]
            event_dict[event_type] = events[event_type]

        return ((record[0], event_list, event_dict, record[3]))

    def add_event_mentions(record):
        lst = record[1]
        event_dict = {}

        for item in lst:
            event_dict[item[0]] = {"Mentions":item[1]}

        return ((record[0], event_dict, record[2], record[3]))

    def add_total(record):
        events = record[1]
        event_info = record[2]

        for key in event_info:
            events[key].update(event_info[key])
            events["event_count"] = {"total":record[3]}

        return ((record[0], events))

    # Ingest Data
    raw_data = ingest_data(rdd, time_period)

    # Validate data
    valid_data = raw_data.filter(valid_record) \
                     .map(lambda x: (x[1], int(x[2]), x[3], x[4], x[5], int(x[6]), round(float(x[7]),2), round(float(x[8]),2)))

    # Add metadata to the data
    data_info = valid_data.map(get_event_code) \
                           .filter(lambda x: x[0] in country_names and x[2] in event_names and ("C"+x[3]) in event_cause ) \
                           .map(lambda x: (country_names[x[0]], x[1], event_names[x[2]]+":"+event_cause["C"+x[3]], x[4], x[5], x[6]))

    # Add keys to data
    data_key = data_info.map(lambda x: ((x[0], x[1], x[2]), (x[3],x[4],x[5],1))) \
    	             .reduceByKey(lambda x,y: (x[0]+y[0], x[1]+y[1], x[2]+y[2], x[3]+y[3])) \
    	             .map(lambda x: (x[0], (x[1][0], round(x[1][1]/x[1][3],2), round(x[1][2]/x[1][3],2))))

    # Sort data based on the key
    data_sort = data_key.map(lambda x: ((x[0][0],x[0][1]),
                       ([(x[0][2],x[1][0])], [(x[0][2],{"avg_score":x[1][1], "avg_tone":x[1][2]})]))) \
                   .reduceByKey(lambda x, y: (x[0]+y[0], x[1]+y[1])) \
                   .map(lambda v: (v[0], sorted(v[1][0], key=itemgetter(1), reverse=True), v[1][1]))

    # Add event info to the data
    data_events = data_sort.map(add_event_info) \
                        .map(lambda x: (x[0], x[1][:10], dict(x[2]), x[3])) \
                        .map(add_top_events)

    # Add mentions to the data
    final_event_data = data_events.map(add_event_mentions) \
                              .map(add_total) \
                              .map(lambda x: (x[0][0], x[0][1], x[1]))

    return final_event_data

monthly_data = process_data(rdd, "daily")
print monthly_data.first()
monthly_data.saveToCassandra("gdelt","daily")
