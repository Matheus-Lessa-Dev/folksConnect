class DownloadDto {
  final String name;
  final String contentType;
  final List<int> bytes;
  DownloadDto(this.name, this.contentType, this.bytes);
}
