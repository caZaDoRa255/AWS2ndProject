# resource "google_project_service" "firestore" {
#   project = var.project_id
#   service = "firestore.googleapis.com"
#   disable_on_destroy = false  # destroy 시 비활성화하지 않음(권장)
# }

# # Firestore 데이터베이스 생성
# resource "google_firestore_database" "database" {
#   name        = "default"
#   location_id = "us-central1"
#   type        = "FIRESTORE_NATIVE"
#   project     = var.project_id
#   depends_on = [google_project_service.firestore]

#   # Firestore Native 모드에서 사용 가능한 설정
#   concurrency_mode = "OPTIMISTIC"
  
# }

# # Firestore 인덱스 (필요한 경우)
# resource "google_firestore_index" "user_index" {
#   collection = "users"
#   project    = var.project_id

#   fields {
#     field_path = "email"
#     order      = "ASCENDING"
#   }

#   fields {
#     field_path = "created_at"
#     order      = "DESCENDING"
#   }
# }

# # 콘텐츠 인덱스
# resource "google_firestore_index" "content_index" {
#   collection = "contents"
#   project    = var.project_id

#   fields {
#     field_path = "category"
#     order      = "ASCENDING"
#   }

#   fields {
#     field_path = "created_at"
#     order      = "DESCENDING"
#   }
# }

# # 채팅 로그 인덱스
# resource "google_firestore_index" "chatlog_index" {
#   collection = "chatlogs"
#   project    = var.project_id

#   fields {
#     field_path = "user_id"
#     order      = "ASCENDING"
#   }

#   fields {
#     field_path = "timestamp"
#     order      = "DESCENDING"
#   }
# }

# # 클릭 로그 인덱스
# resource "google_firestore_index" "clicklog_index" {
#   collection = "clicklogs"
#   project    = var.project_id

#   fields {
#     field_path = "user_id"
#     order      = "ASCENDING"
#   }

#   fields {
#     field_path = "content_id"
#     order      = "ASCENDING"
#   }

#   fields {
#     field_path = "timestamp"
#     order      = "DESCENDING"
#   }
# }

# # Firestore 보안 규칙
# resource "google_firestore_document" "firestore_rules" {
#   project     = var.project_id
#   collection  = "_firestore_rules"
#   document_id = "rules"
#   fields      = jsonencode({
#     "rules" = {
#       stringValue = <<EOF
# rules_version = '2';
# service cloud.firestore {
#   match /databases/{database}/documents {
#     // 사용자 문서 규칙
#     match /users/{userId} {
#       allow read, write: if request.auth != null && request.auth.uid == userId;
#       allow read: if request.auth != null; // 관리자용 읽기 권한
#     }
    
#     // 콘텐츠 문서 규칙
#     match /contents/{contentId} {
#       allow read: if true; // 모든 사용자가 읽기 가능
#       allow write: if request.auth != null && request.auth.token.admin == true; // 관리자만 쓰기 가능
#     }
    
#     // 채팅 로그 규칙
#     match /chatlogs/{logId} {
#       allow read, write: if request.auth != null;
#     }
    
#     // 클릭 로그 규칙
#     match /clicklogs/{logId} {
#       allow read, write: if request.auth != null;
#     }
    
#     // 선호도 규칙
#     match /preferences/{userId} {
#       allow read, write: if request.auth != null && request.auth.uid == userId;
#     }
    
#     // 구독 규칙
#     match /subscriptions/{subscriptionId} {
#       allow read, write: if request.auth != null;
#     }
    
#     // 즐겨찾기 규칙
#     match /favorites/{favoriteId} {
#       allow read, write: if request.auth != null;
#     }
#   }
# }
# EOF
#     }
#   })
# } 