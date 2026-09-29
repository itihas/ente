use super::VideoIndex;

const FTYP_BOX_MIN_SIZE: u32 = 8;

// Real ftyp boxes are usually 16-32 bytes. The larger ceiling allows unusual
// brand lists while rejecting accidental matches in image data.
const FTYP_BOX_MAX_SIZE: u32 = 1024;

// Image-only brands are intentionally excluded.
const KNOWN_VIDEO_BRANDS: &[[u8; 4]] = &[
    *b"isom", *b"iso2", *b"iso5", *b"iso6", *b"mp41", *b"mp42", *b"mp71", *b"M4V ", *b"M4VP",
    *b"avc1", *b"mmp4", *b"3gp4", *b"3gp5", *b"3gp6", *b"qt  ", *b"MSNV", *b"dash", *b"f4v ",
];

// Some phones embed preview and full MP4s in either order. Return the largest
// valid segment.
pub(super) fn find_largest_ftyp_segment(bytes: &[u8]) -> Option<VideoIndex> {
    let len = bytes.len();
    if len < 12 {
        return None;
    }

    let mut starts: Vec<usize> = Vec::new();
    let last = len.saturating_sub(8);
    let mut i = 4;
    while i <= last {
        if bytes[i] == b'f' && bytes[i + 1] == b't' && bytes[i + 2] == b'y' && bytes[i + 3] == b'p'
        {
            let box_start = i - 4;
            let box_size = u32::from_be_bytes([
                bytes[box_start],
                bytes[box_start + 1],
                bytes[box_start + 2],
                bytes[box_start + 3],
            ]);
            // An ftyp box at byte 0 belongs to a standalone MP4.
            if (FTYP_BOX_MIN_SIZE..=FTYP_BOX_MAX_SIZE).contains(&box_size) && box_start > 0 {
                let brand: [u8; 4] = [bytes[i + 4], bytes[i + 5], bytes[i + 6], bytes[i + 7]];
                if KNOWN_VIDEO_BRANDS.contains(&brand) {
                    starts.push(box_start);
                }
            }
        }
        i += 1;
    }

    if starts.is_empty() {
        return None;
    }
    if starts.len() == 1 {
        return Some(VideoIndex {
            start: starts[0],
            end: len,
        });
    }

    let mut best_index = VideoIndex {
        start: starts[0],
        end: starts[1],
    };
    let mut best_size = 0usize;
    for (idx, &start) in starts.iter().enumerate() {
        let end = if idx + 1 < starts.len() {
            starts[idx + 1]
        } else {
            len
        };
        let size = end - start;
        if size > best_size {
            best_size = size;
            best_index = VideoIndex { start, end };
        }
    }
    Some(best_index)
}
