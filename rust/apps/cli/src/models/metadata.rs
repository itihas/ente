use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct FileMetadata {
    #[serde(rename = "fileType")]
    pub file_type: Option<i32>,
    pub title: Option<String>,
    pub creation_time: Option<i64>,
    pub modification_time: Option<i64>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub hash: Option<String>,
    #[serde(rename = "imageHash")]
    pub image_hash: Option<String>,
    #[serde(rename = "videoHash")]
    pub video_hash: Option<String>,
    #[serde(flatten)]
    pub other: HashMap<String, Value>,
}

impl FileMetadata {
    pub fn get_title(&self) -> Option<&str> {
        self.title.as_deref()
    }

    pub fn get_file_type(&self) -> FileType {
        match self.file_type {
            Some(0) => FileType::Image,
            Some(1) => FileType::Video,
            Some(2) => FileType::LivePhoto,
            _ => FileType::Unknown,
        }
    }

    pub fn is_live_photo(&self) -> bool {
        matches!(self.get_file_type(), FileType::LivePhoto)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum FileType {
    Image = 0,
    Video = 1,
    LivePhoto = 2,
    Unknown = 127,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PublicMetadata {
    pub edited_name: Option<String>,
    pub edited_time: Option<i64>,
    pub caption: Option<String>,
    #[serde(flatten)]
    pub other: HashMap<String, Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PrivateMetadata {
    #[serde(flatten)]
    pub data: HashMap<String, Value>,
}
