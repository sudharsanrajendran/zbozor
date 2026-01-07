import 'package:flutter_test/flutter_test.dart';
import 'package:Ebozor/data/cubits/category/fetch_sub_categories_cubit.dart';
import 'package:Ebozor/data/cubits/item/fetch_item_from_category_cubit.dart';
import 'package:Ebozor/data/cubits/auth/authentication_cubit.dart';
import 'package:Ebozor/data/repositories/category_repository.dart';
import 'package:Ebozor/data/repositories/item/item_repository.dart';
import 'package:Ebozor/data/model/category_model.dart';
import 'package:Ebozor/data/model/data_output.dart';
import 'package:Ebozor/data/model/item/item_model.dart';
import 'package:Ebozor/data/model/item_filter_model.dart';
import 'package:Ebozor/utils/login/lib/login_system.dart';
import 'package:Ebozor/utils/login/lib/payloads.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Ebozor/utils/login/lib/login_status.dart';

// --- MOCKS ---

class MockCategoryRepository implements CategoryRepository {
  bool shouldFail = false;
  List<CategoryModel> mockCategories = [
    CategoryModel(id: 1, name: "Apartment", url: "url1"),
    CategoryModel(id: 2, name: "Villa", url: "url2"),
  ];

  @override
  Future<DataOutput<CategoryModel>> fetchCategories({
    required int page,
    int? categoryId,
  }) async {
    if (shouldFail) {
      throw Exception("Network Error");
    }
    return DataOutput(total: mockCategories.length, modelList: mockCategories);
  }
}

class MockItemRepository implements ItemRepository {
  bool shouldFail = false;
  List<ItemModel> mockItems = [
    ItemModel(id: 101, name: "Luxury Apartment", price: 1000),
    ItemModel(id: 102, name: "Cozy Villa", price: 2000),
  ];

  @override
  Future<DataOutput<ItemModel>> fetchItemFromCatId({
    required int categoryId,
    required int page,
    String? search,
    String? sortBy,
    int? areaId,
    String? city,
    String? country,
    String? state,
    ItemFilterModel? filter,
  }) async {
    if (shouldFail) {
      throw Exception("Item Fetch Error");
    }
    return DataOutput(total: mockItems.length, modelList: mockItems);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockMultiAuthentication extends MMultiAuthentication {
  bool shouldFail = false;

  MockMultiAuthentication(Map<String, LoginSystem> systems) : super(systems);

  @override
  Future<UserCredential?> login() async {
    if (shouldFail) {
      throw Exception("Login Failed");
    }
    return null;
  }

  @override
  void init() {}

  @override
  void listen(Function(MLoginState state) fn) {}
}

// --- TESTS ---

void main() {
  group('Full App Logic Tests', () {
    // 1. FetchSubCategoriesCubit
    group('FetchSubCategoriesCubit', () {
      late FetchSubCategoriesCubit cubit;
      late MockCategoryRepository mockRepository;

      setUp(() {
        mockRepository = MockCategoryRepository();
        cubit = FetchSubCategoriesCubit(categoryRepository: mockRepository);
      });

      tearDown(() {
        cubit.close();
      });

      test('emits Success with categories', () async {
        final future = cubit.fetchSubCategories(categoryId: 1);
        expectLater(
            cubit.stream,
            emitsInOrder([
              isA<FetchSubCategoriesInProgress>(),
              isA<FetchSubCategoriesSuccess>(),
            ]));
        await future;
        expect((cubit.state as FetchSubCategoriesSuccess).categories.length, 2);
      });

      test('emits Failure on error', () async {
        mockRepository.shouldFail = true;
        final future = cubit.fetchSubCategories(categoryId: 1);
        expectLater(
            cubit.stream,
            emitsInOrder([
              isA<FetchSubCategoriesInProgress>(),
              isA<FetchSubCategoriesFailure>(),
            ]));
        await future;
      });
    });

    // 2. FetchItemFromCategoryCubit
    group('FetchItemFromCategoryCubit', () {
      late FetchItemFromCategoryCubit cubit;
      late MockItemRepository mockRepository;

      setUp(() {
        mockRepository = MockItemRepository();
        cubit = FetchItemFromCategoryCubit(itemRepository: mockRepository);
      });

      tearDown(() {
        cubit.close();
      });

      test('emits Success with items', () async {
        final future = cubit.fetchItemFromCategory(categoryId: 10, search: "");
        expectLater(
            cubit.stream,
            emitsInOrder([
              isA<FetchItemFromCategoryInProgress>(),
              isA<FetchItemFromCategorySuccess>(),
            ]));
        await future;
        expect(
            (cubit.state as FetchItemFromCategorySuccess).itemModel.length, 2);
      });

      test('emits Failure on error', () async {
        mockRepository.shouldFail = true;
        final future = cubit.fetchItemFromCategory(categoryId: 10, search: "");
        expectLater(
            cubit.stream,
            emitsInOrder([
              isA<FetchItemFromCategoryInProgress>(),
              isA<FetchItemFromCategoryFailure>(),
            ]));
        await future;
      });
    });

    // 3. AuthenticationCubit (Basic State Check)
    group('AuthenticationCubit', () {
      late AuthenticationCubit cubit;
      late MockMultiAuthentication mockAuth;

      setUp(() {
        mockAuth = MockMultiAuthentication({});
        cubit = AuthenticationCubit(multiAuthentication: mockAuth);
      });

      tearDown(() {
        cubit.close();
      });

      test('initial state is Initial', () {
        expect(cubit.state, isA<AuthenticationInitial>());
      });

      test('login emits Failure when auth fails', () async {
        mockAuth.shouldFail = true;
        // CORRECTED: Using Named Parameters
        cubit.setData(
            type: AuthenticationType.email,
            payload: EmailLoginPayload(
                email: "test@test.com",
                password: "pass",
                type: EmailLoginType.login));

        // Trigger login
        cubit.authenticate();

        // Assert
        expectLater(
            cubit.stream,
            emitsInOrder([
              isA<AuthenticationInProcess>(),
              isA<AuthenticationFail>(),
            ]));
      });
    });
  });
}
