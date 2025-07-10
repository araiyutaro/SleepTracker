#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw

def create_notification_icon(size):
    """通知用のシンプルでかわいい月のアイコンを作成"""
    # 透明な背景
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # パディング
    padding = size * 0.1
    inner_size = size - 2 * padding
    
    # 月の形を描画（三日月）
    moon_color = (123, 104, 238)  # 紫色
    
    # 月の外側の円
    draw.ellipse([padding, padding, padding + inner_size, padding + inner_size], 
                 fill=moon_color)
    
    # 月をくり抜く円（透明にして三日月を作る）
    cutout_offset = inner_size * 0.3
    draw.ellipse([padding + cutout_offset, padding - cutout_offset * 0.5, 
                  padding + inner_size + cutout_offset, padding + inner_size - cutout_offset * 0.5], 
                 fill=(0, 0, 0, 0))
    
    # 小さな星を追加
    star_size = max(2, int(size * 0.05))
    star_positions = [
        (padding + inner_size * 0.7, padding + inner_size * 0.3),
        (padding + inner_size * 0.8, padding + inner_size * 0.5),
        (padding + inner_size * 0.65, padding + inner_size * 0.7),
    ]
    
    for x, y in star_positions:
        draw.ellipse([x - star_size, y - star_size, 
                      x + star_size, y + star_size], 
                     fill=(255, 215, 0))  # 金色
    
    return img

def main():
    # Android通知アイコンのサイズ
    android_sizes = {
        'mdpi': 24,
        'hdpi': 36,
        'xhdpi': 48,
        'xxhdpi': 72,
        'xxxhdpi': 96,
    }
    
    print("通知アイコンを生成中...")
    
    # Androidディレクトリを作成
    for density in android_sizes:
        dir_path = f'android/app/src/main/res/drawable-{density}'
        os.makedirs(dir_path, exist_ok=True)
        
        size = android_sizes[density]
        icon = create_notification_icon(size)
        icon.save(f'{dir_path}/ic_notification.png')
        print(f"生成完了: {dir_path}/ic_notification.png ({size}x{size})")
    
    # iOSの通知アイコンも生成（オプション）
    ios_notification_sizes = [20, 40, 60]
    ios_dir = 'ios/Runner/Assets.xcassets/NotificationIcon.imageset'
    os.makedirs(ios_dir, exist_ok=True)
    
    for i, size in enumerate(ios_notification_sizes, 1):
        icon = create_notification_icon(size)
        filename = f'notification-icon-{size}@{i}x.png'
        icon.save(f'{ios_dir}/{filename}')
        print(f"生成完了: {ios_dir}/{filename} ({size}x{size})")
    
    # iOS Contents.jsonを作成
    contents_json = '''{{
  "images" : [
    {{
      "filename" : "notification-icon-20@1x.png",
      "idiom" : "universal",
      "scale" : "1x"
    }},
    {{
      "filename" : "notification-icon-40@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    }},
    {{
      "filename" : "notification-icon-60@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }}
  ],
  "info" : {{
    "author" : "xcode",
    "version" : 1
  }}
}}'''
    
    with open(f'{ios_dir}/Contents.json', 'w') as f:
        f.write(contents_json)
    
    print("\n通知アイコンの生成が完了しました！")

if __name__ == '__main__':
    main()