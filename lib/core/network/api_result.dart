class ApiResult<T> {
  final int statusCode;
  final String message;
  final T data;

  const ApiResult({
    required this.statusCode,
    required this.message,
    required this.data,
  });
}
