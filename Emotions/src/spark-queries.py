from pyspark import SparkContext, SparkConf
from pyspark.sql import SQLContext
from pyspark.sql.types import *
from pyspark.sql.functions import udf
from pyspark.sql.functions import col
from pyspark.sql.types import StringType, DoubleType, IntegerType
from abbreviations_dict import tofullname, toevent
from operator import itemgetter
from pyspark import StorageLevel
import pyspark_cassandra

sc = SparkContext()
sqlContext = SQLContext(sc)

def modify_values(r,y):
   if r == '' and y != '':
	return y
   else:
        return r

def country_exists(r):
   if r in tofullname:
        return tofullname[r]
   else:
	return ''

def event_exists(r):
   if r in toevent:
	return toevent[r]
   else:
	return ''

c_exists = udf(country_exists,StringType())
e_exists = udf(event_exists,StringType())
dfsub1 =  df.withColumn("ActionGeo_CountryCode",c_exists(col("ActionGeo_CountryCode"))) \
	    .withColumn("Actor1Type1Code",e_exists(col("Actor1Type1Code")))
      
sqlContext.registerDataFrameAsTable(dfsub1, 'temp')
df2 = sqlContext.sql("""SELECT ActionGeo_CountryCode,
                               CAST(SQLDATE AS INTEGER), CAST(MonthYear AS INTEGER), CAST(Year AS INTEGER),
                               CASE WHEN Actor1Type1Code = '' AND Actor2Type1Code <> '' THEN Actor2Type1Code
				    ELSE Actor1Type1Code END AS Actor1Type1Code,
                               CAST(NumArticles AS INTEGER),
                               CAST(GoldsteinScale AS INTEGER),
                               CAST(AvgTone AS INTEGER)
                          FROM temp
                         WHERE ActionGeo_CountryCode <> '' AND ActionGeo_CountryCode IS NOT NULL
                            AND Actor1Type1Code <> '' AND Actor1Type1Code IS NOT NULL
                            AND NumArticles <> '' AND NumArticles IS NOT NULL
                            AND GoldsteinScale <> '' AND GoldsteinScale IS NOT NULL
                            AND AvgTone <> '' AND AvgTone IS NOT NULL""")

sqlContext.dropTempTable('temp')
sqlContext.registerDataFrameAsTable(df2, 'temp3')
sqlContext.cacheTable('temp3')

dfdaily = sqlContext.sql("""SELECT ActionGeo_CountryCode,
				   SQLDATE,
				   Actor1Type1Code,
				   SUM(NumArticles) AS NumArticles,
                                   ROUND(AVG(GoldsteinScale),0) AS GoldsteinScale,
			           ROUND(AVG(AvgTone),0) AS AvgTone
			      FROM temp3
			     GROUP BY ActionGeo_CountryCode,
				      SQLDATE,
				      Actor1Type1Code""")

dfmonthly = sqlContext.sql("""SELECT ActionGeo_CountryCode,
				     MonthYear,
				     Actor1Type1Code,
				     SUM(NumArticles) AS NumArticles,
				     ROUND(AVG(GoldsteinScale),0) AS GoldsteinScale,
                		     ROUND(AVG(AvgTone),0) as AvgTone
                		 FROM temp3
			        GROUP BY ActionGeo_CountryCode,
					 MonthYear,
					 Actor1Type1Code""")

dfyearly = sqlContext.sql("""SELECT ActionGeo_CountryCode,
				    Year,
				    Actor1Type1Code,
				    SUM(NumArticles) AS NumArticles,
				    ROUND(AVG(GoldsteinScale),0) AS GoldsteinScale,
                                    ROUND(AVG(AvgTone),0) as AvgTone
			       FROM temp3
			      GROUP BY ActionGeo_CountryCode,
				       Year,
				       Actor1Type1Code""")

rdd_format = rd.map(lambda y: ((y["ActionGeo_CountryCode"],y[timeframe]),
                                   ([(y["Actor1Type1Code"],y["NumArticles"])],
				    [(y["Actor1Type1Code"],
                                    {"Goldstein":y["GoldsteinScale"],"ToneAvg":y["AvgTone"]})]))) \
                   .reduceByKey(lambda a, b: (a[0]+b[0], a[1]+b[1])) \
		   .map(lambda v: (v[0],
				   sorted(v[1][0],key=itemgetter(1),reverse=True),
				   dict(v[1][1]))) \
                   .map(sum_allevents) \
                   .map(popular_avg) \
        	   .map(event_todict) \
                   .map(merge_info) \
        	   .map(lambda d: ((d[0][0],d[0][1],d[1])))

    return rdd_format
