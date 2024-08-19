
<img src="https://github.com/user-attachments/assets/1efe7c1b-3d83-4c00-884f-1a0a646f2133" width="12.5%" height="25%">

# 갤러리

<p align="leading">

<img src="https://github.com/user-attachments/assets/3026d654-8d66-40ac-9e3a-504e64088142" width="19%" height="25%">
<img src="https://github.com/user-attachments/assets/c3e0f5c8-f3cd-4a95-b248-6ac6574bab2c" width="19%" height="25%">
<img src="https://github.com/user-attachments/assets/57dfd794-5737-463d-aa5e-19bfd72c4eba" width="19%" height="25%">
<img src="https://github.com/user-attachments/assets/c9cf8879-cfca-4746-bd6b-01c60a3ccbbf" width="19%" height="25%">   
<img src="https://github.com/user-attachments/assets/e78d4cf8-7f44-4483-8226-22387236d87d" width="19%" height="25%">
</p>


>2024.08.06 ~ 2024.08.13

## 기술

- SwiftUI
- Photos
- MapKit
- AVFoundation
- AVKit
- CoreLocation
- Swift Concurrency
- GCD

## 작동 GIF
<p align="leading">

<img src="https://github.com/user-attachments/assets/de1a8d81-88a8-4c5a-b1b5-07715ceb401a" width="25%" height="30%">
<img src="https://github.com/user-attachments/assets/a5ab36f9-9120-4581-b12e-86cf3accbaa3" width="25%" height="30%">
<img src="https://github.com/user-attachments/assets/8306b15d-c1ba-4cf5-9f91-e9d08dc3c0ef" width="25%" height="30%">
</p>


## 목표 및 구현 기능

**기존 사진앱과 흡사한 기능을 개발(달성률 약 78%)**
- [x] 항목 및 앨범 별 리스트
- [x] 핀치 제스처를 통한 그리드 조정
- [x] 리스트 시간 순 정렬 및 비율 조절  
- [x] 이미지&비디오 뷰어
- [x] 각 항목별 상세정보
- [x] 항목 즐겨 찾기 추가 기능
- [x] 항목 삭제 기능
- [ ] 이미지 크롭 및 저장
- [ ] 앨범 추가 기능


## Trouble Shooting
### 이슈1
  - 이미지 업로드 시 메모리 사용량이 지속적으로 증가하여 비정상적으로 앱이 종료되는 문제가 발생.
### 해결 
  - 접근 : 갤러리의 데이터량을 고려하여 페이지네이션을 적용하고, 데이터를 쪼개서 불러오는 방법을 시도.
  - 결과 : 페이지네이션을 적용했지만, 메모리 증가 문제 해결에는 효과가 없음.
  - 발견 : 이미지를 불러올 때 항목 개수에 비례해 클래스 인스턴스가 생성되는 것을 확인.
  - 방법 : 데이터 간 인스턴스 공유를 통해 메모리 사용을 최적화.
  ```swift
      
  internal func loadAssets(){
      //필터링,정렬 등 받아온 결괏값의 옵션을 부여할 수 있는 클래스
      let fetchOptions = PHFetchOptions()
      //날짜 순으로 내림차순
      fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
      //Assets(항목)을 받아오는 메서드 (PHFetchResult 클래스 타입)
      let fetchResult = PHAsset.fetchAssets(with: fetchOptions)
      //1. Assets Results의 파라미터 (asset,index,stop) 중 Assets만 사용(일단은)
      //2. 페이지를 차례로 넘기는 메서드를 새로 구현하여 사용
  		//3. 2번은 문제가 아니였기에 다시 처음부터 모든 Assets을 가져와 assets배열에 저장
      let group = DispatchGroup()
      let userInteractiveQueue = DispatchQueue.global(qos: .userInteractive)
      let mainQueue = DispatchQueue.main
      group.enter()
      userInteractiveQueue.async{
          defer{ group.leave() }
          fetchResult.enumerateObjects { (asset, _, _) in
              mainQueue.async{ [weak self] in
                  self?.assets.append(asset)
              }
          }
      }
      group.notify(queue: userInteractiveQueue){
          mainQueue.async{ [weak self] in
              self?.progress = false
          }
      }
      //이미지 로딩 중일땐 UI가 제대로 작동하지 않아, 로딩 될때까지 Progress를 띄우고 완료되었을때 Progress disAppear하기 위한 로직
  }     
  ```
### 이슈2
  - 항목을 넘기다가 닫을 경우 이전까지 화면에 등장했던 항목들이 닫을때 같은 상태를 공유하는 듯하게 보임
  - <img src="https://github.com/user-attachments/assets/e4f8149e-fc71-43e5-954e-52f1b60d6703" width="20%" height="25%">
  

### 해결  
  - ![스크린샷 2024-08-12 오전 11 00 03](https://github.com/user-attachments/assets/439fb91a-8b64-4285-a4fe-4006da99acc2)
  - 원인 : matchedGeometryEffect가 서로 연동된 View끼리 같은 화면 내에 존재할 경우 생긴다고 함
  - 해결 : 항목을 리스트에서 터치했을 때 기존에 항목리스트는 항목뷰에 덮어져 있고 실제로는 화면상에 논리적으로 존재하기 때문에 항목이 나타날 시 항목리스트는 사라지도록 수정

### 이슈3
  - 즐겨찾기 후 해당 항목 새로고침 구현 중 로직을 변경해야하는 문제
  - 기존에는 처음에 받아온 항목 리스트를 get-only로 구현되어있었음.
  - 하지만 즐겨찾기 및 삭제 기능을 위해 상태 변경 시 해당 항목이 즉시 반영되도록 구현하기 위해야함(get-only 리스트를 사용할 수 없음)
- 접근
  - 항목 리스트 분류를 분류.
    
    1. 전체 항목: 모든 항목의 리스트.
    2. 앨범 리스트 항목: 유저별로 페이지 아이템 개수가 다름.
    3. 필터 리스트 항목: 유저별로 개수가 동일하며 고유 값임.
 
  - **필터 리스트 항목**은 **전체 항목**에서 조건에 따라 필터링하여 얻을 수 있음(리스트를 새로 불러올 필요가 없음).
  - **앨범 리스트 항목**은 개별적으로 새 요청이 필요해서 번거로움이 존재.
  - enum TypeFilter를 사용하여 상황에 맞는 리스트를 반환했으나, get-only 리스트를 사용하지 않기 때문에 이벤트 발생 시 배열을 직접 변경해야 하는 수고가 있음.
  - 또한, **전체 항목** → **필터 리스트 항목** 또는 **앨범 리스트 항목** → **필터 리스트 항목** 요청 시 **전체 항목**을 계속 요청해야 함.
### 해결
  - **전체 항목**을 처음 한 번만 캐싱하고, 인스턴스가 살아있는 동안 계속 사용할 수 있도록 수정.
  - **앨범 리스트**는 매번 새로 요청해야 하지만, **전체 항목**과 **필터 리스트**에 대해서는 캐싱된 배열을 사용하도록 변경.



## 배운점

> 자신이 개발하기 쉬운 방법보다 사용자에게 더 직관적이고 편리한 서비스를 개발해야 한다.


개발을 하면서 본인이 개발한 것에 대해 "이 정도면 충분하다"는 생각이 들 때가 많았습니다. 
하지만 그에 안도하지 않고, 타인의 시각에서 어떻게 보일지, 다른 유사 서비스와의 차별점은 무엇인지 계속해서 고민했습니다. 
이를 통해 객관적으로 더 나은 서비스를 개발하기 위해 노력했습니다.

> 아직 내가 모르는 기술은 내가 알고 있는 기술보다 훨씬 많다.

개인적으로 또는 팀원들과 함께 여러 서비스를 구현해보며 많은 지식과 기술을 얻었다고 스스로 생각했습니다. 
그러나 이번 과제를 진행하면서 처음 도전한 기술들인 동영상 처리, 대량의 데이터 트래픽 관리 방법 등의 여러 기술과 사용 방법을 조사해보니, 아직도 배워야 할 기술이 매우 많다는 것을 실감했습니다. 
본인의 부족함을 항상 인지하고, 더 배우고 더 성장해야겠다는 다짐을 하게 되었습니다.

> 디자인도 좋지만 성능을 신경쓰자.

앱 개발을 결심한 이유가 여러 서비스를 경험하며 직접 이런 프로그램을 내 손으로 개발해보고 싶었기 때문입니다. 
그래서인지 디자인 요소 개발에 많은 시간이 허비되고, 앱의 성능 최적화에 필요한 시간과 노력을 충분히 투자하지 못했다고 생각합니다.
앱을 개발하면서 무엇이 가장 중요한지, 그리고 내 약점을 파악할 수 있는 기회가 되었습니다.








  
