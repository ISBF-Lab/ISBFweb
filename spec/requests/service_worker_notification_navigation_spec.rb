# frozen_string_literal: true

RSpec.describe StaticController do
  describe "#service_worker_asset" do
    def notification_clicks(window_clients)
      get "/service-worker.js"
      expect(response).to have_http_status(:ok)
      context = MiniRacer::Context.new
      context.eval(<<~JAVASCRIPT)
        var notificationCalls = [];
        var handlers = {};
        var self = {
          addEventListener: function (name, handler) { handlers[name] = handler; }
        };
        var clients = {
          matchAll: function () {
            return Promise.resolve(#{window_clients.to_json}.map(function (attributes) {
              return Object.assign(attributes, {
                focus: function () {
                  notificationCalls.push({ focus: attributes.id });
                  return Promise.resolve();
                },
                postMessage: function (message) {
                  notificationCalls.push({ client: attributes.id, message: message });
                }
              });
            }));
          },
          openWindow: function (url) {
            notificationCalls.push({ open: url });
            return Promise.resolve();
          }
        };
      JAVASCRIPT
      context.eval(response.body)
      context.eval(<<~JAVASCRIPT)
        handlers.notificationclick({
          notification: {
            data: { baseUrl: "https://forum.example", url: "/t/topic/100/8" },
            close: function () {}
          },
          waitUntil: function (promise) {}
        });
      JAVASCRIPT
      JSON.parse(context.eval("JSON.stringify(notificationCalls)"))
    ensure
      context&.dispose
    end

    it "requests navigation even when an existing window already has the target URL" do
      expect(
        notification_clicks(
          [{ id: "existing", url: "https://forum.example/t/topic/100/8", frameType: "top-level" }],
        ),
      ).to eq(
        [
          { "focus" => "existing" },
          { "client" => "existing", "message" => { "url" => "/t/topic/100/8" } },
        ],
      )
    end

    it "ignores embedded frames when reusing a forum window" do
      expect(
        notification_clicks(
          [
            { id: "embed", url: "https://forum.example/t/topic/100/8", frameType: "nested" },
            { id: "forum", url: "https://forum.example/latest", frameType: "top-level" },
          ],
        ),
      ).to eq(
        [
          { "focus" => "forum" },
          { "client" => "forum", "message" => { "url" => "/t/topic/100/8" } },
        ],
      )
    end

    it "opens the exact reply when no reusable forum window exists" do
      expect(notification_clicks([])).to eq([{ "open" => "https://forum.example/t/topic/100/8" }])
    end
  end
end
