class WebhookController < ApplicationController
  require 'line/bot'
  require 'wikipedia'

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

      if event.message['text'] != nil
        #LINEで送られてきた文書を取得
        word = event.message['text']
      end

      #日本語版wikipediaの設定
      Wikipedia.Configure {
        domain 'ja.wikipedia.org'
        path   'w/api.php'
      }

      #wikipediaから情報を取得する
      page = Wikipedia.find(word)
      
      #内容とURLを返す
      response = page.summary + "\n" + page.fullurl

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
          client.reply_message(event['replyToken'], message)
        end
      end
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