sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(String message, dynamic error) failure,
    required R Function() loading,
    required R Function() empty,
  }) {
    if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else if (this is Failure<T>) {
      final f = this as Failure<T>;
      return failure(f.message, f.error);
    } else if (this is Loading<T>) {
      return loading();
    } else {
      return empty();
    }
  }

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
  bool get isLoading => this is Loading<T>;
  bool get isEmpty => this is Empty<T>;

  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final dynamic error;
  const Failure(this.message, [this.error]);
}

class Loading<T> extends Result<T> {
  const Loading();
}

class Empty<T> extends Result<T> {
  const Empty();
}
