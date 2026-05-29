// [DOMAIN]
export 'domain/entities/user_entity.dart';
export 'domain/entities/credentials_entity.dart';
export 'domain/repository/auth_repository.dart';
export 'domain/usecases/login_usecase.dart';
export 'domain/usecases/register_usecase.dart';
export 'domain/usecases/resend_usecase.dart';
export 'domain/usecases/verify_usecase.dart';
export 'domain/usecases/magic_link_usecase.dart';

// [DATA]
export 'data/models/user_model.dart';
export 'data/models/credentials_model.dart';
export 'data/services/auth_service.dart';
export 'data/repository/auth_repository_impl.dart';

// [PRESENTATION]
export 'presentation/bloc/auth_bloc.dart';
export 'presentation/bloc/auth_event.dart';
export 'presentation/bloc/auth_state.dart';
export 'presentation/widgets/auth_textfield.dart';
export 'presentation/pages/authentication_page.dart';
export 'presentation/pages/register_page.dart';
export 'presentation/pages/login_page.dart';
export 'presentation/pages/verify_email_page.dart';
export 'presentation/pages/verification_success_page.dart';
export 'presentation/pages/homepage.dart';
