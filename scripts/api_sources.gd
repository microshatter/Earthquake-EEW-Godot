extends Node

@export var eqUrls: Dictionary = {
  "niedLatest": "http://www.kmoni.bosai.go.jp/webservice/server/pros/latest.json",
  "jmaEew2_http": "http://www.kmoni.bosai.go.jp/webservice/hypo/eew",
  "jmaEqlist_http": "https://api.p2pquake.net/v2/history?codes=551&limit=1",
  "usgsEqlist_http":
	"https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_week.geojson",
  "wolfx_ws": ["wss://ws-api.wolfx.jp/all_eew"],
  "fan_ws": ["wss://ws.fanstudio.tech/all", "wss://ws.fanstudio.hk/all"],
  "p2pquake_ws": ["wss://api.p2pquake.net/v2/ws"],
};
@export var tsunamiUrls: Dictionary = {
  "jmaTsunami_http": "https://api.p2pquake.net/v2/history?codes=552&limit=1",
};
@export var seisNetUrls: Dictionary = {
  "nied": {
	"stationList":
	  "https://weather-kyoshin.east.edge.storage-yahoo.jp/SiteList/sitelist.json",
	"stationData":
	  "https://weather-kyoshin.east.edge.storage-yahoo.jp/RealTimeData",
  },
  "kma": [
	"wss://ws.fanstudio.tech/kma-station",
	"wss://ws.fanstudio.hk/kma-station",
  ],
};
@export var utilUrls: Dictionary = {
  "geoIp": "https://api.wolfx.jp/geoip.php",
  "ntpTime": "https://api.fanstudio.tech/tool/ntp.php",
};
@export var typhoonUrls: Dictionary = {
  "typhoon_http": "https://api.fanstudio.tech/we/typhoon.php",
};
