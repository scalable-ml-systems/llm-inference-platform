import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  stages: [
    { duration: "30s", target: 5 },   // ramp to 5 VUs
    { duration: "60s", target: 5 },   // hold
    { duration: "30s", target: 15 },  // ramp to 15 VUs
    { duration: "90s", target: 15 },  // hold
    { duration: "20s", target: 0 },   // ramp down
  ],
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(95)<60000"], // adjust based on your system
  },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:8080";
const PATH_CHAT = __ENV.PATH_CHAT || "/v1/chat/completions";
const MODEL = __ENV.MODEL || "TheBloke/Mistral-7B-Instruct-v0.2-AWQ";

export default function () {
  const url = `${BASE_URL}${PATH_CHAT}`;
  const payload = JSON.stringify({
    model: MODEL,
    messages: [{ role: "user", content: "Explain TTFT vs E2E latency in one paragraph." }],
    temperature: 0.2,
    max_tokens: 128,
    stream: false,
  });

  const params = {
    headers: {
      "Content-Type": "application/json",
      // "Authorization": `Bearer ${__ENV.TOKEN}`,
    },
    timeout: "120s",
  };

  const res = http.post(url, payload, params);

  check(res, {
    "status is 200": (r) => r.status === 200,
  });

  sleep(0.5);
}
