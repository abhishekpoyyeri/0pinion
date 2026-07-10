use axum::{
    extract::{Path, State},
    http::StatusCode,
    response::IntoResponse,
    routing::{get},
    Json, Router,
};
use serde_json::{Value, Map};
use std::sync::Arc;
use tokio::sync::Mutex;
use std::fs;
use tower_http::cors::CorsLayer;

type DbState = Arc<Mutex<Value>>;

#[tokio::main]
async fn main() {
    // Load database
    let db_content = fs::read_to_string("db.json").expect("Failed to read db.json");
    let db: Value = serde_json::from_str(&db_content).expect("Failed to parse db.json");
    let state = Arc::new(Mutex::new(db));

    // Setup routes
    let app = Router::new()
        .route("/:table", get(get_all).post(create_item))
        .route("/:table/:id", get(get_item).put(update_item).delete(delete_item))
        .layer(CorsLayer::permissive())
        .with_state(state);

    // Start server
    let port = 3002;
    let listener = tokio::net::TcpListener::bind(format!("0.0.0.0:{}", port)).await.unwrap();
    println!("Rust Mock Server running on http://localhost:{}", port);
    axum::serve(listener, app).await.unwrap();
}

// Helper to save DB to file
async fn save_db(db: &Value) {
    if let Ok(content) = serde_json::to_string_pretty(db) {
        let _ = fs::write("db.json", content);
    }
}

// GET /:table
async fn get_all(
    Path(table): Path<String>,
    State(state): State<DbState>,
) -> impl IntoResponse {
    let db = state.lock().await;
    if let Some(table_data) = db.get(&table) {
        (StatusCode::OK, Json(table_data.clone())).into_response()
    } else {
        (StatusCode::NOT_FOUND, Json(serde_json::json!({"error": "Table not found"}))).into_response()
    }
}

// GET /:table/:id
async fn get_item(
    Path((table, id)): Path<(String, String)>,
    State(state): State<DbState>,
) -> impl IntoResponse {
    let db = state.lock().await;
    if let Some(table_data) = db.get(&table).and_then(|t| t.as_array()) {
        if let Some(item) = table_data.iter().find(|i| i.get("id").and_then(|id_val| id_val.as_str()) == Some(&id)) {
            return (StatusCode::OK, Json(item.clone())).into_response();
        }
    }
    (StatusCode::NOT_FOUND, Json(serde_json::json!({"error": "Item not found"}))).into_response()
}

// POST /:table
async fn create_item(
    Path(table): Path<String>,
    State(state): State<DbState>,
    Json(mut payload): Json<Map<String, Value>>,
) -> impl IntoResponse {
    let mut db = state.lock().await;
    if let Some(table_data) = db.get_mut(&table).and_then(|t| t.as_array_mut()) {
        let new_id = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_millis().to_string();
        payload.insert("id".to_string(), Value::String(new_id));
        let new_item = Value::Object(payload);
        table_data.push(new_item.clone());
        
        save_db(&db).await;
        (StatusCode::CREATED, Json(new_item)).into_response()
    } else {
        (StatusCode::NOT_FOUND, Json(serde_json::json!({"error": "Table not found"}))).into_response()
    }
}

// PUT /:table/:id
async fn update_item(
    Path((table, id)): Path<(String, String)>,
    State(state): State<DbState>,
    Json(mut payload): Json<Map<String, Value>>,
) -> impl IntoResponse {
    let mut db = state.lock().await;
    if let Some(table_data) = db.get_mut(&table).and_then(|t| t.as_array_mut()) {
        if let Some(item) = table_data.iter_mut().find(|i| i.get("id").and_then(|id_val| id_val.as_str()) == Some(&id)) {
            // Ensure ID isn't modified
            payload.insert("id".to_string(), Value::String(id));
            
            // Note: Since we are using Map<String, Value>, it replaces the whole item. 
            // In a real patch we would merge them, but for this mock we replace it.
            *item = Value::Object(payload);
            
            save_db(&db).await;
            return (StatusCode::OK, Json(item.clone())).into_response();
        }
    }
    (StatusCode::NOT_FOUND, Json(serde_json::json!({"error": "Item not found"}))).into_response()
}

// DELETE /:table/:id
async fn delete_item(
    Path((table, id)): Path<(String, String)>,
    State(state): State<DbState>,
) -> impl IntoResponse {
    let mut db = state.lock().await;
    if let Some(table_data) = db.get_mut(&table).and_then(|t| t.as_array_mut()) {
        let initial_len = table_data.len();
        table_data.retain(|i| i.get("id").and_then(|id_val| id_val.as_str()) != Some(&id));
        
        if table_data.len() < initial_len {
            save_db(&db).await;
            return (StatusCode::OK, Json(serde_json::json!({"success": true}))).into_response();
        }
    }
    (StatusCode::NOT_FOUND, Json(serde_json::json!({"error": "Item not found"}))).into_response()
}
