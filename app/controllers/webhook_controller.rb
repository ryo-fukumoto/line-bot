class WebhookController < ApplicationController
  require 'line/bot'
  require 'wikipedia'
  require 'net/http'
  require 'uri'
  require 'json'
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
      case event
        #メッセージが送信された場合
        when Line::Bot::Event::Message
          
        case event.type
          #テキストが送信された場合
          when Line::Bot::Event::MessageType::Text
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
            message = {
              type: 'text',
              text: response
            }

          #位置情報が送信された場合
          when Line::Bot::Event::MessageType::Location
            latitude = event.message['latitude'] # 緯度
            longitude = event.message['longitude'] # 経度
            uri = URI.parse(BASE_URL + "?lat=#{latitude}&lon=#{longitude}&APPID=#{API_KEY}")
            json = Net::HTTP.get(uri)
            result = JSON.parse(json)
            weather_status = result['list'][0]['weather'][0]['main']
            temp = result['list'][0]['main']['temp']
            #ケルビンをセルシウス度に変換
            celsius = temp - 273.15
            celsius_round = celsius.round
            weather = "weather：#{weather_status}" + "\n" + "temperature：#{celsius_round}℃"

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