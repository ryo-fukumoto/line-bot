task callback_task: :environment do
webhook_controller = WebhookController.new
webhook_controller.callback
end