import http from 'k6/http';

export const options = {
  stages: [
    { duration: '20s', target: 1000 },
    { duration: '30s', target: 2000 },
    { duration: '10s', target: 5000 },
    { duration: '30s', target: 2000 },
    { duration: '1m', target: 2500 },
    { duration: '20s', target: 0 },
  ],
  thresholds: {
    'http_req_duration': ['p(50)<1000', 'p(75)<1500', 'p(90)<1800', 'p(95)<2000', 'p(99)<3000'],
  },
  summaryTrendStats: ["avg", "min", "max", "p(50)", "p(75)", "p(90)", "p(95)", "p(99)"],
};

export function setup() {
  let startTime = new Date().toISOString();
  console.log(`
    ========================================================
    🟢 TES DIMULAI (Waktu Mulai)
    Silakan copy waktu ini ke Grafana "From":
    
    ${startTime}
    
    ========================================================
    `);
  
  return { testStartTime: startTime };
}

export function teardown(data) {
  let endTime = new Date().toISOString();
  console.log(`
    ========================================================
    🔴 TES SELESAI (Waktu Selesai)
    Silakan copy waktu ini ke Grafana "To":
    
    ${endTime}
    
    ========================================================
    `);
}

export default function () {
  http.get('http://10.98.211.92/test') //your-endpoint;
}