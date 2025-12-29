use std::env;

#[tokio::test]
async fn vps_health_and_plans() {
    // Guard so this test runs only when RUN_VPS_INTEGRATION=1 is set in the environment
    if env::var("RUN_VPS_INTEGRATION").is_err() {
        eprintln!("Skipping VPS integration tests (set RUN_VPS_INTEGRATION=1 to enable)");
        return;
    }

    let base = env::var("VPS_BASE_URL").unwrap_or_else(|_| "http://143.110.185.159:8080/api".to_string());
    let client = reqwest::Client::builder().build().expect("client");

    // health
    let resp = client
        .get(format!("{}/health", base))
        .send()
        .await
        .expect("request");
    assert!(resp.status().is_success(), "health endpoint failed: {}", resp.status());
    let body = resp.text().await.expect("body");
    assert!(body.trim() == "OK", "unexpected health body: {}", body);

    // internet_plans
    let resp2 = client
        .get(format!("{}/internet_plans", base))
        .send()
        .await
        .expect("request2");
    assert!(resp2.status().is_success(), "internet_plans failed: {}", resp2.status());
    let json = resp2.json::<serde_json::Value>().await.expect("json");
    assert!(json.is_array(), "internet_plans did not return array");
}
