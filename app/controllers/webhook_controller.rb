class WebhookController < ApplicationController
  require 'line/bot'
  require 'wikipedia'
  require 'net/http'
  require 'uri'
  require 'json'
  require "open-uri"
  API_KEY = "07233f6700c510c4a78b505afa2bb250"
  BASE_URL = "http://api.openweathermap.org/data/2.5/forecast"


  # callbakアクションのCSRFトークン認証を無効化
  protect_from_forgery except: :callback

  def callback
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      error 400 do 'Bad Request' end
    end

    events = client.parse_events_from(body)
    events.each { |event|

      #wikipediaの設定
      if event.message['text']
        #LINEで送られてきた文書を取得
        word = event.message['text']
        #日本語化
        Wikipedia.Configure {
          domain 'ja.wikipedia.org'
          path   'w/api.php'
        }
        #wikipediaから情報を取得する
        page = Wikipedia.find(word)
        #内容とURLを返す
        response = page.summary + "\n" + page.fullurl
      end

      #天気情報の設定
      # uri = URI.parse('http://weather.livedoor.com/forecast/webservice/json/v1?city=270000')
      # json = Net::HTTP.get(uri)
      # result = JSON.parse(json)
      # today_tel = result['forecasts'][0]['telop']
      # min_tem =   result['forecasts'][1]['temperature']['min']['celsius']
      # max_tem =   result['forecasts'][1]['temperature']['max']['celsius']
      # weather = "今日の天気は#{today_tel}" + "\n" + "最低気温#{min_tem}℃" + "\n" + "最高気温#{max_tem}℃"

      case event
        #メッセージが送信された場合
        when Line::Bot::Event::Message
          
        case event.type
          #テキストが送信された場合
          when Line::Bot::Event::MessageType::Text
            message = {
              type: 'text',
              text: response
            }
          #位置情報が送信された場合
          when Line::Bot::Event::MessageType::Location
            latitude = event.message['latitude'] # 緯度
            longitude = event.message['longitude'] # 経度
            location_response = open(BASE_URL + "?lat=#{latitude}&lon=#{longitude}&APPID=#{API_KEY}")
            result = JSON.parse(location_response.read))
            weather = result[:list][0][:main][:temp]
            message = {
              type: 'text',
              text: weather
            }
        end
      end
      client.reply_message(event['replyToken'], message)
    }
    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end
end