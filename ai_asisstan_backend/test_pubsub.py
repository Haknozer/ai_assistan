#!/usr/bin/env python
"""Pub/Sub paket kontrolü"""
try:
    from google.cloud import pubsub_v1
    print("✅ SUCCESS: google-cloud-pubsub paketi yüklü!")
    print(f"   Version: {pubsub_v1.__version__ if hasattr(pubsub_v1, '__version__') else 'bilinmiyor'}")
except ImportError as e:
    print(f"❌ ERROR: google-cloud-pubsub paketi yüklü değil!")
    print(f"   Hata: {e}")
    print("\nYüklemek için:")
    print("   pip install google-cloud-pubsub")

