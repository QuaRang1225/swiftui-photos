import SwiftUI
import Photos

struct CropImageView: View {
    @State private var size = CGSize()
    @Binding var frame: CGSize
    let asset:PHAsset
    
    @State var grid = false
    @State private var horizontalScale: CGFloat = 1.0 // 가로 방향 스케일
    @State private var verticalScale: CGFloat = 1.0   // 세로 방향 스케일
    @State private var offset: CGSize = .zero          // 드래그 오프셋
    @State private var previousHorizontalScale: CGFloat = 1.0 // 이전 가로 스케일
    @State private var previousVerticalScale: CGFloat = 1.0   // 이전 세로 스케일
    @State private var accumulatedOffset = CGSize.zero
    
    @State var area:AnyView?
    @State var image:UIImage?
    @Binding var dismiss:Bool
    
    @EnvironmentObject var vm:PhotoViewModel
    var body: some View {
        VStack {
            Button {
                crop()
            } label: {
                Image(systemName: "heart")
                    .foregroundColor(.white)
            }
            
            Button {
                dismiss = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
            }
            
            //            PhotosItemView(assets: .constant(asset))
            Image("q")
                .resizable()
                .scaledToFit()
                .frame(width: frame.width, height: frame.height)
//                .mask{
//                    ZStack {
//                        Rectangle()
//                            .opacity(0.5)
//                        Rectangle()
////                            .frame(width: 100 * horizontalScale, height: 100 * verticalScale)
////                            .offset(x: offset.width, y: offset.height)
////                            .position(x: frame.width / 2, y: frame.height / 2)
//
//                    }
//                    
//                }
            
                .overlay {
//                    var cropArea:some View{
                       cropArea
//                    }
                }
            //                .background(Color.gray)
        }
        .overlay(content: {
            if let image{
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 200,height: 200)
            }
            
        })
        .environmentObject(vm)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
    var cropArea:some View{
        Rectangle()
            .overlay {
                controllView
                    .foregroundColor(.white)
                    .simultaneousGesture(resizingDrag) // 크기 조정 제스처 추가
                if grid{
                    gridView
                }
            }
            .overlay(Rectangle().stroke(lineWidth: 1).foregroundColor(.white))
            .gesture(movingDrag)
            .frame(width: 100 * horizontalScale, height: 100 * verticalScale)
            .offset(x: offset.width, y: offset.height)
            .position(x: frame.width / 2, y: frame.height / 2)
            .onAppear {
                size = offset
            }
            .opacity(0.5)
    }
    var controllView: some View {
        VStack(alignment: .trailing, spacing: 0) {
            Spacer()
            HStack(alignment: .bottom, spacing: 0) {
                Spacer()
                Rectangle()
                    .frame(width: 20, height: 10)
                Rectangle()
                    .frame(width: 10, height: 30)
            }
        }
    }
    var gridView:some View{
        ZStack{
            HStack{
                ForEach(1...4,id: \.self){ _ in
                    Rectangle()
                        .foregroundColor(.white)
                        .frame(width: 1)
                        .frame(maxWidth:.infinity)
                    
                }
            }
            VStack{
                ForEach(1...4,id: \.self){ _ in
                    Rectangle()
                        .foregroundColor(.white)
                        .frame(height: 1)
                        .frame(maxHeight:.infinity)
                    
                }
            }
        }
    }
    
    var resizingDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                withAnimation{ grid = true }
                
                let deltaX = value.translation.width
                let deltaY = value.translation.height
                let newHorizontalScale = max(0.5, previousHorizontalScale + deltaX / 100)
                let newVerticalScale = max(0.5, previousVerticalScale + deltaY / 100)
                
                if (100 * newHorizontalScale) < frame.width && (100 * newVerticalScale) < frame.height {
                    self.horizontalScale = newHorizontalScale
                    self.verticalScale = newVerticalScale
                    
                    let newWidth = 100 * horizontalScale
                    let newHeight = 100 * verticalScale
                    
                    let maxOffsetX = max(0, (frame.width - newWidth) / 2)
                    let maxOffsetY = max(0, (frame.height - newHeight) / 2)
                    
                    self.offset = CGSize(
                        width: min(maxOffsetX, max(-maxOffsetX, offset.width)),
                        height: min(maxOffsetY, max(-maxOffsetY, offset.height))
                    )
                }
            }
            .onEnded { _ in
                // 드래그가 끝난 후 현재 스케일 값을 저장
                withAnimation{ grid = false }
                self.previousHorizontalScale = self.horizontalScale
                self.previousVerticalScale = self.verticalScale
                
            }
    }
    
    var movingDrag: some Gesture {
        DragGesture()
        //            .onChanged { gesture in
        //                if (100 * horizontalScale) < frame.width && (100 * verticalScale) < frame.height{
        //                    offset = accumulatedOffset + gesture.translation
        //                    accumulatedOffset = offset
        //                }
        //              }
        //              .onEnded { gesture in
        //                accumulatedOffset = accumulatedOffset + gesture.translation
        //              }
            .onChanged { gesture in
                // 이미지의 현재 위치와 크기를 계산
                
                withAnimation{ grid = true }
                let currentWidth = 100 * horizontalScale
                let currentHeight = 100 * verticalScale
                
                // 이미지의 최대 오프셋 값을 계산
                let maxOffsetX = max(0, (frame.width - currentWidth) / 2)
                let maxOffsetY = max(0, (frame.height - currentHeight) / 2)
                
                // 새로운 오프셋 값 계산
                let newOffsetX = offset.width + gesture.translation.width
                let newOffsetY = offset.height + gesture.translation.height
                
                // 오프셋 값을 한계 내로 제한
                let clampedOffsetX = min(max(newOffsetX, -maxOffsetX), maxOffsetX)
                let clampedOffsetY = min(max(newOffsetY, -maxOffsetY), maxOffsetY)
                
                // 제한된 오프셋 값을 적용
                offset = CGSize(width: clampedOffsetX, height: clampedOffsetY)
            }
            .onEnded { _ in
                // 드래그가 끝난 후 현재 위치를 누적 오프셋으로 저장
                withAnimation{ grid = false }
                accumulatedOffset = offset
            }
    }
    func crop(){
        let renderer = ImageRenderer(content: cropArea)
//        renderer.proposedSize = .init(CGSize(width:  100 * horizontalScale, height:  100 * verticalScale))
        if let image = renderer.uiImage{
            //               onCrop(image,true)
            self.image = image
        }
        //        else{
        ////               onCrop(nil,false)
        //           }
    }
}

#Preview {
    CropImageView(frame: .constant(CGSize(width: 393, height: 222)), asset: PHAsset(), dismiss: .constant(false))
        .environmentObject(PhotoViewModel())
}
