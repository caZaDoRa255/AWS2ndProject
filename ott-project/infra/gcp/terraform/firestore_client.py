# import firebase_admin
# from firebase_admin import credentials, firestore
# from datetime import datetime
# import json

# class FirestoreClient:
#     def __init__(self, project_id):
#         """
#         Firestore 클라이언트 초기화
        
#         Args:
#             project_id (str): GCP 프로젝트 ID
#         """
#         # 서비스 계정 키 파일 경로 (실제 환경에 맞게 수정)
#         cred = credentials.Certificate("path/to/service-account-key.json")
        
#         # Firebase 앱 초기화
#         firebase_admin.initialize_app(cred, {
#             'projectId': project_id
#         })
        
#         # Firestore 클라이언트 생성
#         self.db = firestore.client()
    
#     def add_user(self, user_id, user_data):
#         """
#         사용자 추가
        
#         Args:
#             user_id (str): 사용자 ID
#             user_data (dict): 사용자 데이터
#         """
#         user_data['created_at'] = datetime.now()
#         user_data['updated_at'] = datetime.now()
        
#         self.db.collection('users').document(user_id).set(user_data)
#         print(f"사용자 {user_id}가 추가되었습니다.")
    
#     def get_user(self, user_id):
#         """
#         사용자 조회
        
#         Args:
#             user_id (str): 사용자 ID
            
#         Returns:
#             dict: 사용자 데이터
#         """
#         doc = self.db.collection('users').document(user_id).get()
#         if doc.exists:
#             return doc.to_dict()
#         return None
    
#     def add_content(self, content_id, content_data):
#         """
#         콘텐츠 추가
        
#         Args:
#             content_id (str): 콘텐츠 ID
#             content_data (dict): 콘텐츠 데이터
#         """
#         content_data['created_at'] = datetime.now()
#         content_data['updated_at'] = datetime.now()
        
#         self.db.collection('contents').document(content_id).set(content_data)
#         print(f"콘텐츠 {content_id}가 추가되었습니다.")
    
#     def get_contents_by_category(self, category):
#         """
#         카테고리별 콘텐츠 조회
        
#         Args:
#             category (str): 카테고리
            
#         Returns:
#             list: 콘텐츠 목록
#         """
#         docs = self.db.collection('contents').where('category', '==', category).stream()
#         return [doc.to_dict() for doc in docs]
    
#     def add_chat_log(self, user_id, message, response):
#         """
#         채팅 로그 추가
        
#         Args:
#             user_id (str): 사용자 ID
#             message (str): 사용자 메시지
#             response (str): 챗봇 응답
#         """
#         log_data = {
#             'user_id': user_id,
#             'message': message,
#             'response': response,
#             'timestamp': datetime.now()
#         }
        
#         self.db.collection('chatlogs').add(log_data)
#         print("채팅 로그가 추가되었습니다.")
    
#     def add_click_log(self, user_id, content_id, action_type="view"):
#         """
#         클릭 로그 추가
        
#         Args:
#             user_id (str): 사용자 ID
#             content_id (str): 콘텐츠 ID
#             action_type (str): 액션 타입 (view, like, share 등)
#         """
#         log_data = {
#             'user_id': user_id,
#             'content_id': content_id,
#             'action_type': action_type,
#             'timestamp': datetime.now()
#         }
        
#         self.db.collection('clicklogs').add(log_data)
#         print(f"클릭 로그가 추가되었습니다: {action_type}")
    
#     def add_preference(self, user_id, preferences):
#         """
#         사용자 선호도 추가/업데이트
        
#         Args:
#             user_id (str): 사용자 ID
#             preferences (dict): 선호도 데이터
#         """
#         preferences['updated_at'] = datetime.now()
        
#         self.db.collection('preferences').document(user_id).set(preferences, merge=True)
#         print(f"사용자 {user_id}의 선호도가 업데이트되었습니다.")
    
#     def add_subscription(self, user_id, subscription_data):
#         """
#         구독 정보 추가
        
#         Args:
#             user_id (str): 사용자 ID
#             subscription_data (dict): 구독 데이터
#         """
#         subscription_data['user_id'] = user_id
#         subscription_data['created_at'] = datetime.now()
#         subscription_data['updated_at'] = datetime.now()
        
#         self.db.collection('subscriptions').add(subscription_data)
#         print(f"사용자 {user_id}의 구독이 추가되었습니다.")
    
#     def add_favorite(self, user_id, content_id):
#         """
#         즐겨찾기 추가
        
#         Args:
#             user_id (str): 사용자 ID
#             content_id (str): 콘텐츠 ID
#         """
#         favorite_data = {
#             'user_id': user_id,
#             'content_id': content_id,
#             'created_at': datetime.now()
#         }
        
#         self.db.collection('favorites').add(favorite_data)
#         print(f"즐겨찾기가 추가되었습니다: {content_id}")
    
#     def get_user_favorites(self, user_id):
#         """
#         사용자의 즐겨찾기 목록 조회
        
#         Args:
#             user_id (str): 사용자 ID
            
#         Returns:
#             list: 즐겨찾기 목록
#         """
#         docs = self.db.collection('favorites').where('user_id', '==', user_id).stream()
#         return [doc.to_dict() for doc in docs]

# # 사용 예제
# if __name__ == "__main__":
#     # Firestore 클라이언트 초기화
#     client = FirestoreClient("ott-project-462006")
    
#     # 사용자 추가 예제
#     user_data = {
#         'email': 'user@example.com',
#         'name': '홍길동',
#         'age': 30,
#         'is_admin': False
#     }
#     client.add_user("user123", user_data)
    
#     # 콘텐츠 추가 예제
#     content_data = {
#         'title': '샘플 콘텐츠',
#         'description': '이것은 샘플 콘텐츠입니다.',
#         'category': 'movie',
#         'duration': 120,
#         'rating': 4.5
#     }
#     client.add_content("content123", content_data)
    
#     # 채팅 로그 추가 예제
#     client.add_chat_log("user123", "안녕하세요", "안녕하세요! 무엇을 도와드릴까요?")
    
#     # 클릭 로그 추가 예제
#     client.add_click_log("user123", "content123", "view")
    
#     # 선호도 추가 예제
#     preferences = {
#         'favorite_genres': ['action', 'comedy'],
#         'preferred_language': 'ko',
#         'auto_play': True
#     }
#     client.add_preference("user123", preferences)
    
#     # 즐겨찾기 추가 예제
#     client.add_favorite("user123", "content123")
    
#     print("모든 예제가 실행되었습니다.") 