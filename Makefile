build_android_full:
	make build_apk && make build_appbundle

build_apk:
	./scripts/build_android.sh --package_type=apk && \
	open build/app/outputs/flutter-apk

build_appbundle:
	./scripts/build_android.sh --package_type=appbundle && \
	open build/app/outputs/bundle/release
