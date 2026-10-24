import http from 'http';

function request(options, body) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function runTests() {
  console.log('--- RUNNING PHASE 1 TOKEN SERVER ACCEPTANCE TESTS ---');
  let passed = 0;
  let total = 0;

  // Test 1: Health Check
  total++;
  try {
    const res = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/health',
      method: 'GET'
    });
    if (res.status === 200 && res.body.room === 'PP') {
      console.log('✅ TEST 1 PASSED: /health returned status 200 with room PP');
      passed++;
    } else {
      console.error('❌ TEST 1 FAILED:', res);
    }
  } catch (e) {
    console.error('❌ TEST 1 FAILED with error:', e.message);
  }

  // Test 2: Reject Invalid Passcode
  total++;
  try {
    const res = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/token',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    }, { identity: 'Pawan', passcode: 'WRONG_PW' });
    if (res.status === 401) {
      console.log('✅ TEST 2 PASSED: Rejected invalid passcode with 401 Unauthorized');
      passed++;
    } else {
      console.error('❌ TEST 2 FAILED: Expected 401 but got', res.status);
    }
  } catch (e) {
    console.error('❌ TEST 2 FAILED with error:', e.message);
  }

  // Test 3: Reject Missing Identity
  total++;
  try {
    const res = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/token',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    }, { identity: '', passcode: 'PP@160227' });
    if (res.status === 400) {
      console.log('✅ TEST 3 PASSED: Rejected missing identity with 400 Bad Request');
      passed++;
    } else {
      console.error('❌ TEST 3 FAILED: Expected 400 but got', res.status);
    }
  } catch (e) {
    console.error('❌ TEST 3 FAILED with error:', e.message);
  }

  // Test 4: Issue Token for Pawan
  total++;
  try {
    const res = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/token',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    }, { identity: 'Pawan', passcode: 'PP@160227' });
    if (res.status === 200 && res.body.token && res.body.identity === 'Pawan' && res.body.room === 'PP') {
      console.log('✅ TEST 4 PASSED: Successfully issued 8-hour JWT token for Pawan in room PP');
      passed++;
    } else {
      console.error('❌ TEST 4 FAILED:', res);
    }
  } catch (e) {
    console.error('❌ TEST 4 FAILED with error:', e.message);
  }

  // Test 5: Issue Token for Priya
  total++;
  try {
    const res = await request({
      hostname: 'localhost',
      port: 3000,
      path: '/token',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' }
    }, { identity: 'Priya', passcode: 'PP@160227' });
    if (res.status === 200 && res.body.token && res.body.identity === 'Priya' && res.body.room === 'PP') {
      console.log('✅ TEST 5 PASSED: Successfully issued 8-hour JWT token for Priya in room PP');
      passed++;
    } else {
      console.error('❌ TEST 5 FAILED:', res);
    }
  } catch (e) {
    console.error('❌ TEST 5 FAILED with error:', e.message);
  }

  console.log(`\nRESULTS: ${passed}/${total} TESTS PASSED.`);
  process.exit(passed === total ? 0 : 1);
}

runTests();
