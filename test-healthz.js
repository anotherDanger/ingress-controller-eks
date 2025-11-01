import http from 'k6/http';
import { check } from 'k6';
import { Trend } from 'k6/metrics';

const healthzLatency = new Trend('healthz_latency_ms');

export const options = {
  stages: [
    { duration: '30s', target: 500 },
    { duration: '30s', target: 1000 },
    { duration: '30s', target: 2000 },
    { duration: '15s', target: 5000 },
    { duration: '5s', target: 3000 },
    { duration: '2m', target: 2000 },
    { duration: '1.5m', target: 1500 },
    { duration: '2m', target: 2500 },
    { duration: '1.5m', target: 2000 },
    { duration: '10s', target: 1500 },
    { duration: '10s', target: 1000 },
    { duration: '10s', target: 500 },
    { duration: '10s', target: 100 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    'checks': ['rate>0.95'],                
    'http_req_failed': ['rate<0.05'],       
    'http_req_duration': ['p(50)<1000', 'p(75)<1500', 'p(90)<1800', 'p(95)<2000', 'p(99)<3000', 'p(99.9)<4000'], 
    'http_req_connecting': ['max<1000'],     
    'http_req_waiting': ['p(50)<500', 'p(95)<1500'],      
    'healthz_latency_ms': ['p(50)<500', 'p(75)<1000', 'p(90)<1500', 'p(95)<2000', 'p(99)<3000', 'p(99.9)<4000'],    
  },
};

export default function () {
  const res = http.get(''); //your endpoint

  check(res, {
    'status is 200': (r) => r.status === 200,
  });

  healthzLatency.add(res.timings.duration);
}
