# Project Info
This is a software that notify users EEW and earthquake information.  EEW don't have a map, and earthquake information are aligned at center
This project is currently made with Godot 4.7, may update engine later

> [!WARNING]
> This project is AI Generated: parts of the project, including parts of the scripts, were written with the assistance of an AI.
>
> AI-assisted areas include (but are not limited to):
> * Local intensity estimation (`calculate_local_intensity` in `scripts/utils.gd`)
> * Epicentral intensity estimation from magnitude/depth (`magnitude_to_intensity`) and the JMA ⇄ Chinese intensity scale conversions (`chinese_to_jma` / `jma_to_chinese`)

> [!NOTE]
> The intensity calculations are **simplified empirical models for educational use only**, with roughly ±1 unit of uncertainty. They must **not** be used for life-safety decisions or official reporting. For production use, rely on official JMA/CENC real-time systems.

# Data Source
> Copied from [https://github.com/Lipomoea/kanameishi/blob/dev/README.md#数据来源]
* Earthquake Early Warning (CEA/SC/FJ/CWA/JMA), Earthquake Information (CENC), Earthquake List (JMA), IP Geolocation: [Wolfx Open API](https://wolfx.jp/apidoc) (Please refer to the API documentation)
* Earthquake Information (JMA), Tsunami Information (JMA): [P2PQuake](https://www.p2pquake.net/develop/json_api_v2/#/P2P%E5%9C%B0%E9%9C%87%E6%83%85%E5%A0%B1%20API/get_history)
* Earthquake Early Warning (CEA/SC/FJ/CWA/JMA), Earthquake Information (CENC/CWA/USGS/FSSN), Earthquake List (CENC/FSSN), CENC Intensity Report, Typhoon Information, NTP Time: [FAN Studio API](https://api.fanstudio.tech)
* Earthquake Early Warning (CEA/SC/FJ/CWA/JMA), Earthquake Information (CENC/CWA/USGS), Earthquake List (CENC), CENC Intensity Report, Typhoon Information, NTP Time: [WHEWS API](https://api.beecld.com)
* SREV Sound Effects: [scratch-realtime-earthquake-viewer-page](https://github.com/kotoho7/scratch-realtime-earthquake-viewer-page)
* Chinese Countdown Broadcast Material: [地牛Wake Up！](https://eew.earthquake.tw/)
* EEW Sound Effects: NHK

# Credits
* [Maple Font by subframe7536](https://github.com/subframe7536/Maple-font)
