#jsonify creates a json representation of the response
from app import app
from flask import request, redirect, render_template, jsonify
from cassandra.cluster import Cluster
from collections import OrderedDict
import simplejson as json

# importing Cassandra modules from the driver we just installed
cluster = Cluster(['ec2-54-212-219-13.us-west-2.compute.amazonaws.com',
                    'ec2-52-41-205-89.us-west-2.compute.amazonaws.com',
                    'ec2-52-24-85-58.us-west-2.compute.amazonaws.com',
                    'ec2-54-148-6-162.us-west-2.compute.amazonaws.com'])
session = cluster.connect('gdelt')

@app.route('/')
def hello():
    return 'Hello'

@app.route('/monitor')
def query():
    return render_template("world_monitor.html")

@app.route("/monitor",methods=['POST'])
def query_post():
    country = request.json["country"]
    date = request.json["date"]
    period = request.json["period"].lower()
    query = ""
    if period == "daily":
	       query += "SELECT * FROM daily WHERE country = %s and date = %s"
    elif period == "monthly":
	       query += "SELECT * FROM monthly WHERE country = %s and date = %s"
    elif period == "yearly":
	       query += "SELECT * FROM yearly WHERE country = %s and date = %s"
    try:
        result = session.execute(query, parameters = [country,int(date)])[0]
    except Exception:
        return "missing"

    def get_events(ordermap):
        events = {}
        for event in ordermap:
           events[str(event)] = {str(key): value for key, value in ordermap[event].items()}
        return events

    events_dict = get_events(result[2])
    # total_mentions = clean_dict["event_count"]['total']
    events_dict.pop('event_count',None)
    # jsonresponse = {"Events":clean_dict}
    return str(events_dict)

