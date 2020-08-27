#!/usr/bin/env python
# -*- coding:utf-8 -*-

import argparse
import subprocess

from urllib3.contrib import pyopenssl as reqs
from datetime import datetime

## TelegramBotToken
bot_token = "abc:123"
chat_id = "-xxx"


def send_text_str(bot_token, chat_id, textMsg):
    command = 'curl -s -X POST https://api.telegram.org/bot' + bot_token + '/sendMessage -F chat_id=' + chat_id + " -F text='%s'" % textMsg
    subprocess.Popen(command, shell=True)
    return


def get_expiration(www, alarm_value):
    try:
        cert = reqs.OpenSSL.crypto.load_certificate(reqs.OpenSSL.crypto.FILETYPE_PEM,
                                                    reqs.ssl.get_server_certificate((www, 443)))
        notAfter = datetime.strptime(cert.get_notAfter().decode()[0:-1], '%Y%m%d%H%M%S')
        remainDays = notAfter - datetime.now()
        # print(remainDays.days, type(remainDays.days))
        if remainDays.days <= alarm_value:
            # print("网站(%s)的Https证书有效期小于%d天" % (www, alarm_value))
            send_text_str(bot_token, chat_id,
                          "[HttpsCheck]网站(%s)的Https证书有效期小于%d天(可用%d天)" % (www, alarm_value, remainDays.days))
        else:
            print("剩余可用天数：%d %s" % (remainDays.days, www))
    except:
        # print(" 网站不可用 %s" %(www))
        send_text_str(bot_token, chat_id, "[HttpsCheck]网站(%s) 访问失败" % (www))


domain_list = [
    "www.baidu.com",
]

for domain in domain_list:
    get_expiration(domain, 10)
