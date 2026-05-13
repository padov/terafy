import 'dart:async';
import 'package:common/common.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:terafy/core/domain/repositories/subscription_repository.dart';
import 'package:flutter/foundation.dart';
import 'subscription_bloc_models.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final SubscriptionRepository _repository;

  SubscriptionBloc({required SubscriptionRepository repository})
    : _repository = repository,
      super(const SubscriptionState(status: SubscriptionStatusEnum.initial)) {
    on<LoadSubscriptionStatus>(_onLoadSubscriptionStatus);
    on<LoadAvailablePlans>(_onLoadAvailablePlans);
    on<CheckSubscriptionStatus>(_onCheckSubscriptionStatus);
    on<CreateCheckoutSession>(_onCreateCheckoutSession);
  }

  Future<void> _onLoadSubscriptionStatus(LoadSubscriptionStatus event, Emitter<SubscriptionState> emit) async {
    emit(state.copyWith(status: SubscriptionStatusEnum.loading));
    try {
      final status = await _repository.getSubscriptionStatus();
      emit(state.copyWith(status: SubscriptionStatusEnum.loaded, subscriptionStatus: status));
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao carregar status: $e', stackTrace);
      emit(state.copyWith(status: SubscriptionStatusEnum.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onLoadAvailablePlans(LoadAvailablePlans event, Emitter<SubscriptionState> emit) async {
    try {
      final plans = await _repository.getAvailablePlans();
      emit(state.copyWith(status: SubscriptionStatusEnum.loaded, plans: plans));
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao carregar planos: $e', stackTrace);
      emit(state.copyWith(status: SubscriptionStatusEnum.error, errorMessage: e.toString()));
    }
  }

  Future<void> _onCheckSubscriptionStatus(CheckSubscriptionStatus event, Emitter<SubscriptionState> emit) async {
    try {
      final status = await _repository.getSubscriptionStatus();
      emit(state.copyWith(status: SubscriptionStatusEnum.loaded, subscriptionStatus: status));
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao verificar status: $e', stackTrace);
      // Não emite erro para não interromper o fluxo
    }
  }

  Future<void> _onCreateCheckoutSession(CreateCheckoutSession event, Emitter<SubscriptionState> emit) async {
    emit(state.copyWith(status: SubscriptionStatusEnum.loading));
    try {
      // Url base da nossa aplicação na web
      // Em produção precisa ter as URLs dinâmicas com o endereço real (ex: https://terafy.app.br/subscription)
      String successUrl = 'https://terafy.com.br/subscription/success';
      String cancelUrl = 'https://terafy.com.br/subscription/cancel';

      // Usar a URL local se estiver na Web
      if (kIsWeb) {
        final origin = Uri.base.origin;
        successUrl = '$origin/#/subscription';
        cancelUrl = '$origin/#/subscription';
      }

      final url = await _repository.createCheckoutSession(
        planId: event.planId,
        successUrl: successUrl,
        cancelUrl: cancelUrl,
      );

      emit(state.copyWith(status: SubscriptionStatusEnum.checkoutRedirect, checkoutUrl: url));
    } catch (e, stackTrace) {
      AppLogger.error('Erro ao iniciar checkout: $e', stackTrace);
      emit(state.copyWith(status: SubscriptionStatusEnum.error, errorMessage: e.toString()));
    }
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
