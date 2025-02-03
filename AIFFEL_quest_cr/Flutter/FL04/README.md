# 리니지 보스체크기
## 앱정보
## 시장(마켓)
  린저씨에게 잘팔리던 포모도로 어플을 이용한 보스체크기
  지금은 무료로 풀렸지만 한동안 잘팔렸던....
  
# 앱구조도

![도식도](https://github.com/user-attachments/assets/b2d61ffe-9757-4d6d-9318-141977a7b6fd)

#프로토타이핑(사용툴 : 마블앱)

![마블앱](https://github.com/user-attachments/assets/604f5404-fc3e-4a7f-ab24-d7e35ca02cc8)

# 페이지 구현
1. main.dart - 로그인 화면으로 시작해서 허용된 아이디만 Homescreen으로 보내주고 아니면 Error로 보내주고 bottom에는 기능에 맞게 리니지 홈페이지 접속
2. Signup.dart - 로그인을 실패한 회원가입이 되어있지 않은 사람들을 sign(결제) 페이지로 유도
3. App1.dart - 고정보스 스케줄을 보여주는 타블랫(표)를 구현한 페이지
4. App2.dart - 포모도로를 이용한 보스를 잡았을때 체크를 해주는 어플앱

# 구현영상
https://github.com/user-attachments/assets/31e826cc-70cc-48d5-aa7a-b7dfb3e77691

# 회고
1. Routerdelegator를 이용해서 허락된 계정을 로그인하면 ~/User123/one 또는 ~/User123/two로 가는식의 구현은 어려웠다
2. 로그인 list를 만들어서 허락된 아이디만 들어가는것은 구현할수 있었지만 회원가입을 통해 로그인list 업데이트를 하는것은 실패했다.
3. 프로토타이핑을 아주 빠르게 진행했고 복잡하지 않은 구조였지만 코드를 짜는데 시간이 많이 들어갔다.
