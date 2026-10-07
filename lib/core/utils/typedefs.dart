import 'package:fpdart/fpdart.dart';

import '../error/failure.dart';

typedef JsonMap = Map<String, dynamic>;
typedef Result<T> = Either<Failure, T>;
