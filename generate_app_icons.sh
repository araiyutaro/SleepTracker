#!/bin/bash

# アイコン生成スクリプト
# ImageMagickまたはrsvg-convertが必要です

echo "アプリアイコンを生成中..."

# iOS用アイコンディレクトリ
IOS_ICON_DIR="ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Android用アイコンディレクトリ
ANDROID_ICON_DIR="android/app/src/main/res"

# ディレクトリ作成
mkdir -p $IOS_ICON_DIR
mkdir -p $ANDROID_ICON_DIR/mipmap-mdpi
mkdir -p $ANDROID_ICON_DIR/mipmap-hdpi
mkdir -p $ANDROID_ICON_DIR/mipmap-xhdpi
mkdir -p $ANDROID_ICON_DIR/mipmap-xxhdpi
mkdir -p $ANDROID_ICON_DIR/mipmap-xxxhdpi

# iOS用アイコンサイズ
IOS_SIZES=(
  "20:Icon-App-20x20@1x.png"
  "40:Icon-App-20x20@2x.png"
  "60:Icon-App-20x20@3x.png"
  "29:Icon-App-29x29@1x.png"
  "58:Icon-App-29x29@2x.png"
  "87:Icon-App-29x29@3x.png"
  "40:Icon-App-40x40@1x.png"
  "80:Icon-App-40x40@2x.png"
  "120:Icon-App-40x40@3x.png"
  "60:Icon-App-60x60@1x.png"
  "120:Icon-App-60x60@2x.png"
  "180:Icon-App-60x60@3x.png"
  "76:Icon-App-76x76@1x.png"
  "152:Icon-App-76x76@2x.png"
  "167:Icon-App-83.5x83.5@2x.png"
  "1024:Icon-App-1024x1024@1x.png"
)

# Android用アイコンサイズ
ANDROID_SIZES=(
  "48:mipmap-mdpi/ic_launcher.png"
  "72:mipmap-hdpi/ic_launcher.png"
  "96:mipmap-xhdpi/ic_launcher.png"
  "144:mipmap-xxhdpi/ic_launcher.png"
  "192:mipmap-xxxhdpi/ic_launcher.png"
)

# SVGをPNGに変換する関数
convert_svg_to_png() {
  local input=$1
  local size=$2
  local output=$3
  
  # macOSの場合はQLプレビューを使用
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # rsvg-convertがインストールされているか確認
    if command -v rsvg-convert &> /dev/null; then
      rsvg-convert -w $size -h $size $input -o $output
    else
      echo "警告: rsvg-convertがインストールされていません。"
      echo "brew install librsvg でインストールしてください。"
      # 代替案：sipsを使用（品質は劣る可能性あり）
      # 一時的にPNGファイルを作成
      cp assets/images/placeholder_icon.png $output 2>/dev/null || echo "プレースホルダーアイコンを使用"
    fi
  else
    # Linuxの場合
    if command -v convert &> /dev/null; then
      convert -background none -resize ${size}x${size} $input $output
    else
      echo "エラー: ImageMagickがインストールされていません。"
      exit 1
    fi
  fi
}

# プレースホルダーアイコンを作成（SVG変換ツールがない場合用）
create_placeholder_icon() {
  local size=$1
  local output=$2
  local color="#7B68EE"
  
  # macOSのsipsコマンドを使用してシンプルなアイコンを生成
  if [[ "$OSTYPE" == "darwin"* ]]; then
    # 一時的なプレースホルダーを作成
    echo "プレースホルダーアイコンを生成中: $output"
    # シンプルな色付き四角形を作成
    mkdir -p $(dirname $output)
    # Pythonを使用してシンプルなPNGを生成
    python3 -c "
from PIL import Image, ImageDraw
img = Image.new('RGBA', ($size, $size), (123, 104, 238, 255))
draw = ImageDraw.Draw(img)
# 月の形を描画
draw.ellipse([int($size*0.2), int($size*0.2), int($size*0.8), int($size*0.8)], fill=(255, 250, 205, 255))
img.save('$output')
" 2>/dev/null || echo "警告: $output の生成に失敗"
  fi
}

# iOS用アイコン生成
echo "iOS用アイコンを生成中..."
for item in "${IOS_SIZES[@]}"; do
  IFS=':' read -r size filename <<< "$item"
  output="$IOS_ICON_DIR/$filename"
  echo "生成中: $output (${size}x${size})"
  convert_svg_to_png "assets/images/app_icon.svg" $size "$output" || create_placeholder_icon $size "$output"
done

# Android用アイコン生成
echo "Android用アイコンを生成中..."
for item in "${ANDROID_SIZES[@]}"; do
  IFS=':' read -r size path <<< "$item"
  output="$ANDROID_ICON_DIR/$path"
  echo "生成中: $output (${size}x${size})"
  convert_svg_to_png "assets/images/app_icon.svg" $size "$output" || create_placeholder_icon $size "$output"
done

# iOS Contents.jsonファイルを作成
cat > "$IOS_ICON_DIR/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@1x.png",
      "idiom" : "iphone",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-60x60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-60x60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "Icon-App-20x20@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-20x20@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "Icon-App-29x29@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-29x29@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "Icon-App-40x40@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-40x40@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "Icon-App-76x76@1x.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-76x76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "Icon-App-83.5x83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "Icon-App-1024x1024@1x.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "アイコン生成が完了しました！"