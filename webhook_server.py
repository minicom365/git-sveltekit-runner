from flask import Flask, request
import subprocess

app = Flask(__name__)

@app.route("/webhook", methods=["POST"])
def webhook():
    try:
        subprocess.Popen(["/app/pull_and_reload.sh"])
        return "✅ pulled and reloaded", 200
    except Exception as e:
        return f"❌ Error: {str(e)}", 500

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=4000)
