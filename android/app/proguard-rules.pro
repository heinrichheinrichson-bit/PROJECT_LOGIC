# WorkManager (pulled in by Google Mobile Ads) creates its Room database via
# reflection. R8 full mode otherwise removes this no-argument constructor and
# the application crashes in InitializationProvider before Flutter starts.
-keepclassmembers class androidx.work.impl.WorkDatabase_Impl {
    public <init>();
}
