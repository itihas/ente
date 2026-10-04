package s3config

import "testing"

func TestUploadURL(t *testing.T) {
	const signed = "https://hel1.your-objectstorage.com/bucket/key?X-Amz-Signature=abc&X-Amz-SignedHeaders=host"

	unproxied := &S3Config{}
	if got := unproxied.UploadURL(signed); got != signed {
		t.Errorf("without proxy: got %q, want unchanged", got)
	}

	proxied := &S3Config{
		uploadProxyFrom: "https://hel1.your-objectstorage.com",
		uploadProxyTo:   "https://s3.example.org",
	}
	want := "https://s3.example.org/bucket/key?X-Amz-Signature=abc&X-Amz-SignedHeaders=host"
	if got := proxied.UploadURL(signed); got != want {
		t.Errorf("with proxy: got %q, want %q", got, want)
	}

	// A different origin (or one that only shares a prefix) passes through.
	for _, other := range []string{
		"https://fsn1.your-objectstorage.com/bucket/key?sig",
		"https://hel1.your-objectstorage.com.evil.example/bucket/key?sig",
	} {
		if got := proxied.UploadURL(other); got != other {
			t.Errorf("non-matching %q: got %q, want unchanged", other, got)
		}
	}
}
