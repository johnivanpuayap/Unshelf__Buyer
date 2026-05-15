/// Infrastructure Riverpod providers.
///
/// Each abstract repository / service has a default implementation that uses
/// the real Firebase / PayMongo SDKs. Tests can override these via
/// ProviderContainer(overrides: [...]).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unshelf_buyer/data/repositories/auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/firebase/firebase_auth_repository.dart';
import 'package:unshelf_buyer/data/repositories/firebase/firebase_product_repository.dart';
import 'package:unshelf_buyer/data/repositories/firebase/firebase_storage_repository.dart';
import 'package:unshelf_buyer/data/repositories/firebase/firebase_user_repository.dart';
import 'package:unshelf_buyer/data/repositories/product_repository.dart';
import 'package:unshelf_buyer/data/repositories/storage_repository.dart';
import 'package:unshelf_buyer/data/repositories/user_repository.dart';
import 'package:unshelf_buyer/services/paymongo_service.dart';
import 'package:unshelf_buyer/services/wallet_service.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

final userRepositoryProvider = Provider<UserRepository>(
  (ref) => FirebaseUserRepository(),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => FirebaseProductRepository(),
);

final storageRepositoryProvider = Provider<StorageRepository>(
  (ref) => FirebaseStorageRepository(),
);

final walletServiceProvider = Provider<WalletService>(
  (ref) => PayMongoService(),
);
