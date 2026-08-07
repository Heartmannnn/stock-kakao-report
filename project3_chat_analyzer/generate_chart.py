# ==============================================================================
# Project 3: Python PIL Dark Mode Portfolio Chart Generator
# Native cross-platform PNG generator (Runs seamlessly on Linux GitHub Actions & Windows)
# ==============================================================================

import os
from PIL import Image, ImageDraw, ImageFont

def generate_portfolio_chart(output_path="portfolio_chart.png"):
    width = 900
    height = 450
    
    # Slate Dark Mode Colors
    bg_color = (15, 23, 42)     # #0f172a
    card_color = (30, 41, 59)   # #1e293b
    text_main = (248, 250, 252) # #f8fafc
    text_sub = (148, 163, 184)  # #94a3b8
    
    accent_blue = (59, 130, 246)   # S&P500
    accent_green = (16, 185, 129)  # SpaceX
    accent_amber = (245, 158, 11)  # NVDA
    accent_purple = (139, 92, 246) # Cash
    gauge_red = (239, 68, 68)     # Sentiment 65C

    img = Image.new("RGB", (width, height), bg_color)
    draw = ImageDraw.Draw(img)

    # Try loading default fonts, fallback to PIL default
    try:
        font_title = ImageFont.truetype("arial.ttf", 24)
        font_sub = ImageFont.truetype("arial.ttf", 14)
        font_label = ImageFont.truetype("arial.ttf", 16)
        font_val = ImageFont.truetype("arial.ttf", 14)
        font_temp = ImageFont.truetype("arial.ttf", 32)
    except IOError:
        font_title = font_sub = font_label = font_val = font_temp = ImageFont.load_default()

    # Draw Title Banner
    draw.text((30, 25), "SOUL COMPANY RESEARCH PORTFOLIO", fill=text_main, font=font_title)
    draw.text((32, 60), "Estimated Assets & Investor Sentiment Meter (Project 3 Cloud)", fill=text_sub, font=font_sub)

    # Card 1: Asset Allocation (Left Box)
    draw.rectangle([30, 95, 510, 415], fill=card_color)
    draw.text((50, 115), "Asset Allocation (Estimated)", fill=text_main, font=font_label)

    items = [
        {"name": "S&P500 Index ETF", "pct": 45, "color": accent_blue, "text": "45%"},
        {"name": "SpaceX / Private Asset", "pct": 25, "color": accent_green, "text": "25%"},
        {"name": "Nvidia / AI Semiconductor", "pct": 20, "color": accent_amber, "text": "20%"},
        {"name": "Cash / Waiting Position", "pct": 10, "color": accent_purple, "text": "10%"}
    ]

    y_pos = 155
    for it in items:
        draw.text((50, y_pos), it["name"], fill=text_main, font=font_val)
        draw.text((430, y_pos), it["text"], fill=it["color"], font=font_label)
        
        # Background progress bar
        draw.rectangle([50, y_pos + 25, 460, y_pos + 39], fill=(51, 65, 85))
        
        # Filled progress bar
        fill_w = int(410 * (it["pct"] / 100.0))
        draw.rectangle([50, y_pos + 25, 50 + fill_w, y_pos + 39], fill=it["color"])
        
        y_pos += 60

    # Card 2: Sentiment Gauge Meter (Right Box)
    draw.rectangle([540, 95, 870, 415], fill=card_color)
    draw.text((560, 115), "Investor Sentiment Meter", fill=text_main, font=font_label)

    # Thermometer Meter Circle
    draw.ellipse([635, 155, 775, 295], fill=(51, 65, 85))
    draw.ellipse([645, 165, 765, 285], fill=gauge_red)
    draw.ellipse([660, 180, 750, 270], fill=card_color)

    draw.text((672, 210), "65 C", fill=text_main, font=font_temp)
    draw.text((615, 325), "Cautious DCA Accumulation Zone", fill=accent_green, font=font_sub)
    draw.text((630, 355), "Blue-chip Dip Buying Bias", fill=text_sub, font=font_sub)

    img.save(output_path, "PNG")
    print(f"🎨 Visual Portfolio Chart saved to: {output_path}")

if __name__ == "__main__":
    generate_portfolio_chart()
