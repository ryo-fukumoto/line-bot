class WebhookController < ApplicationController
  require 'line/bot'
  require 'wikipedia'
  require 'net/http'
  require 'uri'
  require 'json'

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
      #日本語版wikipediaの設定
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
      uri = URI.parse('http://weather.livedoor.com/forecast/webservice/json/v1?city=270000')
      json = Net::HTTP.get(uri)
      result = JSON.parse(json)
      today_tel = result['forecasts'][0]['telop']
      min_tem =   result['forecasts'][1]['temperature']['min']['celsius']
      max_tem =   result['forecasts'][1]['temperature']['max']['celsius']
      weather = "今日の天気は#{today_tel}" + "\n" + "最低気温#{min_tem}℃" + "\n" + "最高気温#{max_tem}℃"

      case event
        #メッセージが送信された場合
        when Line::Bot::Event::Message
          
        case event.type
          #メッセージが送られてきた場合
          when Line::Bot::Event::MessageType::Text
            message = {
              type: 'text',
              text: response
            }
            
          when Line::Bot::Event::MessageType::Location
            message = {
              type: 'text',
              text: "おはよう"
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