# REMOVAL OF FAN STUDIO NOTICE
## FAN Studio API server shutdown on **2026-12-31 15:59:00 (UTC)**. Here is the announcement below:

FAN Studio API 停止运营通知
谢谢你们，陪我们走过这一年多。

服务终止日期
2026 年 12 月 31 日
经过团队商议与慎重考虑，我们决定：FAN Studio API 将于 2026 年 12 月 31 日 23:59（UTC+8）正式结束运营。 届时，所有接口将停止对外提供服务，不再响应任何请求。

即日起至 2026 年 12 月 31 日 —— 现有接口保持正常运行，功能与调用方式均不做变更。
2026 年 12 月 31 日 23:59 —— API 全面停止服务，所有接口下线。
这一年多里，从第一行代码到第一个调用成功，从深夜的调试到你们发来的一句「好用」， 都是我们非常珍惜的记忆。感谢每一位使用过 FAN Studio API 的开发者， 感谢你们的信任、耐心，以及那些认真写下的反馈与建议。

如果你还在使用这些接口，请提前做好迁移与其他相关安排。 若在过渡期间有任何疑问，欢迎随时联系我们，我们会尽力协助。

聚散有时，但代码与心意会留下。祝你在自己的项目里，继续写出喜欢的东西。

推荐替代 API
如果你还在寻找可用的接口，不妨看看下面，由其他优秀的爱好者维护的服务。

https://api.odysphere.tech/
https://api.2v8.cn/docs
https://ws.mangxufurry.cc.cd/
FAN Studio 团队
2026 · 感谢一路同行

# Project Info
This is a software that notify users EEW and earthquake information.  EEW don't have a map, and earthquake information are aligned at center
This project is currently made with Godot 4.7, may update engine later

> [!WARNING]
> This project name is not final and it will subject to change later

> [!WARNING]
> AI Generated Clarification: parts of the scripts were written with the assistance of an AI.
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
* [Maple Mono Font by subframe7536](https://github.com/subframe7536/Maple-font)
* [DSEG Font by subframe7536](https://github.com/keshikan/DSEG)
