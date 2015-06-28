class VoiceController < ApplicationController
  def index


  end
  def speech
    require 'securerandom'
    require 'net/http'
    require 'net/https'
    require 'uri'
    require 'json'
    require 'wavefile'
    @name = SecureRandom.urlsafe_base64(5)
    @text = params[:eng]
    @lang = params[:lang]
    puts @text


# A note to fix an SSL error
    puts "if encounter the Error: SSL_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed, find the fix in https://gist.github.com/fnichol/867550\n"

# Note: Sign up at http://www.projectoxford.ai to get a subscription key.
# Search for Speech APIs from Azure Marketplace.
# Use the subscription key as Client secret below.

    clientId = "Your ClientId goes here"
    clientSecret = "Your Client Secret goes here"
    speechHost = "https://speech.platform.bing.com"


    post_data = "grant_type=client_credentials&client_id=" + URI.encode(clientId) + "&client_secret=" + URI.encode(clientSecret) + "&scope=" + URI.encode(speechHost)

#print (post_data)
    url = URI.parse("https://oxford-speech.cloudapp.net:443/token/issueToken")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true


    headers = {
        'content-type' => 'application/x-www-form-urlencoded'
    }

# get the Oxford Access Token in json
    resp = http.post(url.path, post_data, headers)
    puts "Oxford Access Token: ", resp.body, "\n"

# decode the json to get the Oxford Access Token object.
    oxfordAccessToken = JSON.parse(resp.body)

    ttsServiceUri = "https://speech.platform.bing.com:443/synthesize"
    url = URI.parse(ttsServiceUri)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true

    headers = {
        'content-type' => 'application/ssml+xml',
        'X-Microsoft-OutputFormat' => 'riff-16khz-16bit-mono-pcm',
        'Authorization' => 'Bearer ' + oxfordAccessToken["access_token"],
        'X-Search-AppId' => '07D3234E49CE426DAA29772419F436CA',
        'X-Search-ClientID' => '1ECFAE91408841A480F00935DC390960',
        'User-Agent' => 'TTSRuby'
    }

# SsmlTemplate = "<speak version='1.0' xml:lang='en-us'><voice xml:lang='%s' xml:gender='%s' name='%s'>%s</voice></speak>"
    case @lang.to_s
      when 'eng'
        data = "<speak version='1.0' xml:lang='en-us'><voice xml:lang='en-US' xml:gender='Female' name='Microsoft Server Speech Text to Speech Voice (en-US, ZiraRUS)'>#{@text}</voice></speak>"
      when 'cht'
        data="<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xmlns:mstts='http://www.w3.org/2001/mstts' xml:lang='zh-TW'><voice name='Microsoft Server Speech Text to Speech Voice (zh-TW, Yating, Apollo)'>#{@text}</voice></speak>"
      when 'jp'
        data="<speak version='1.0' xmlns='http://www.w3.org/2001/10/synthesis' xmlns:mstts='http://www.w3.org/2001/mstts' xml:lang='ja-JP'><voice name='Microsoft Server Speech Text to Speech Voice (ja-JP, Ayumi, Apollo)'>#{@text}</voice></speak>"
    end

    #data = "<speak version='1.0' xml:lang='en-us'><voice xml:lang='en-US' xml:gender='Female' name='Microsoft Server Speech Text to Speech Voice (en-US, ZiraRUS)'>#{@text}</voice></speak>"


# get the wave data
    resp = http.post(url.path, data, headers)

    puts "wave data length: ", resp.body.length

    open("public/tts/#{@name}.wav", "w") do |file|
      file.set_encoding("ASCII-8BIT:utf-8")
      file.print resp.body
    end

    render 'index'

  end


end
