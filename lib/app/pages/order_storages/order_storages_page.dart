import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '/app/constants/strings.dart';
import '/app/data/database.dart';
import '/app/pages/order_storage/order_storage_page.dart';
import '/app/pages/shared/page_view_model.dart';

part 'order_storages_state.dart';
part 'order_storages_view_model.dart';

class OrderStoragesPage extends StatelessWidget {
  OrderStoragesPage({
    Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OrderStoragesViewModel>(
      create: (context) => OrderStoragesViewModel(context),
      child: _OrderStoragesView(),
    );
  }
}

class _OrderStoragesView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Strings.orderStoragesPageName)
      ),
      body: BlocBuilder<OrderStoragesViewModel, OrderStoragesState>(
        builder: (context, state) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 24, left: 8, right: 8, bottom: 24),
            children: state.orderStorages.map((e) => _orderStorageTile(context, e)).toList()
          );
        }
      )
    );
  }

  Widget _orderStorageTile(BuildContext context, OrderStorage orderStorage) {
    return ListTile(
      title: Text(orderStorage.name, style: const TextStyle(fontSize: 14.0)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => OrderStoragePage(orderStorage: orderStorage)
          )
        );
      }
    );
  }
}
