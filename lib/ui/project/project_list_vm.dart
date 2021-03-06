import 'dart:async';
import 'package:invoiceninja_flutter/redux/client/client_actions.dart';
import 'package:invoiceninja_flutter/redux/ui/list_ui_state.dart';
import 'package:redux/redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:built_collection/built_collection.dart';
import 'package:invoiceninja_flutter/utils/completers.dart';
import 'package:invoiceninja_flutter/utils/localization.dart';
import 'package:invoiceninja_flutter/redux/project/project_selectors.dart';
import 'package:invoiceninja_flutter/data/models/models.dart';
import 'package:invoiceninja_flutter/ui/project/project_list.dart';
import 'package:invoiceninja_flutter/redux/app/app_state.dart';
import 'package:invoiceninja_flutter/redux/project/project_actions.dart';

class ProjectListBuilder extends StatelessWidget {
  const ProjectListBuilder({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, ProjectListVM>(
      converter: ProjectListVM.fromStore,
      builder: (context, viewModel) {
        return ProjectList(
          viewModel: viewModel,
        );
      },
    );
  }
}

class ProjectListVM {
  ProjectListVM({
    @required this.user,
    @required this.projectList,
    @required this.projectMap,
    @required this.clientMap,
    @required this.listState,
    @required this.filter,
    @required this.isLoading,
    @required this.isLoaded,
    @required this.onProjectTap,
    @required this.onRefreshed,
    @required this.onEntityAction,
    @required this.onClearEntityFilterPressed,
    @required this.onViewEntityFilterPressed,
  });

  static ProjectListVM fromStore(Store<AppState> store) {
    Future<Null> _handleRefresh(BuildContext context) {
      if (store.state.isLoading) {
        return Future<Null>(null);
      }
      final completer = snackBarCompleter(
          context, AppLocalization.of(context).refreshComplete);
      store.dispatch(LoadProjects(completer: completer, force: true));
      return completer.future;
    }

    final state = store.state;

    return ProjectListVM(
      user: state.user,
      listState: state.projectListState,
      projectList: memoizedFilteredProjectList(
          state.projectState.map,
          state.projectState.list,
          state.projectListState,
          state.clientState.map),
      projectMap: state.projectState.map,
      clientMap: state.clientState.map,
      isLoading: state.isLoading,
      isLoaded: state.projectState.isLoaded,
      filter: state.projectUIState.listUIState.filter,
      onClearEntityFilterPressed: () =>
          store.dispatch(FilterProjectsByEntity()),
      onViewEntityFilterPressed: (BuildContext context) => store.dispatch(
          ViewClient(
              clientId: state.projectListState.filterEntityId,
              context: context)),
      onProjectTap: (context, project) {
        store.dispatch(ViewProject(projectId: project.id, context: context));
      },
      onEntityAction:
          (BuildContext context, BaseEntity project, EntityAction action) =>
              handleProjectAction(context, project, action),
      onRefreshed: (context) => _handleRefresh(context),
    );
  }

  final UserEntity user;
  final List<int> projectList;
  final BuiltMap<int, ProjectEntity> projectMap;
  final BuiltMap<int, ClientEntity> clientMap;
  final ListUIState listState;
  final String filter;
  final bool isLoading;
  final bool isLoaded;
  final Function(BuildContext, ProjectEntity) onProjectTap;
  final Function(BuildContext) onRefreshed;
  final Function(BuildContext, ProjectEntity, EntityAction) onEntityAction;
  final Function onClearEntityFilterPressed;
  final Function(BuildContext) onViewEntityFilterPressed;
}
