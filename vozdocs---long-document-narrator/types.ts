
export enum AppStatus {
  IDLE = 'IDLE',
  PARSING = 'PARSING',
  GENERATING = 'GENERATING',
  READY = 'READY',
  ERROR = 'ERROR'
}

export interface AudioSegment {
  blob: Blob;
  url: string;
}

export interface DocumentInfo {
  name: string;
  size: number;
  pages: number;
  text: string;
}
