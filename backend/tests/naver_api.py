import os
import sys
import urllib.request
import json

from config import settings

naver_search_api_client_id = settings.NAVER_SEARCH_API_CLIENT_SECRET
naver_search_api_client_secret = settings.NAVER_SEARCH_API_CLIENT_SECRET
encText = urllib.parse.quote("역삼청소년수련관")
url = "https://openapi.naver.com/v1/search/image.json?query=" + encText
# url = "https://openapi.naver.com/v1/search/local.json?query=" + encText # JSON 결과
# url = "https://openapi.naver.com/v1/search/blog.xml?query=" + encText # XML 결과
request = urllib.request.Request(url)
request.add_header("X-Naver-Client-Id",client_id)
request.add_header("X-Naver-Client-Secret",client_secret)
response = urllib.request.urlopen(request)
rescode = response.getcode()
if(rescode==200):
    response_body = response.read()
    print(response_body.decode('utf-8'))
else:
    print("Error Code:" + rescode)