import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';

class AdminBolaoManager extends StatefulWidget {
  const AdminBolaoManager({super.key});

  @override
  State<AdminBolaoManager> createState() => _AdminBolaoManagerState();
}

class _AdminBolaoManagerState extends State<AdminBolaoManager> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _deleteBolao(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Bolão'),
        content: Text('Tem certeza que deseja excluir o bolão "$name"? Esta ação não pode ser desfeita e os participantes podem perder seus aportes se não houver estorno automático configurado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('boloes').doc(id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bolão excluído com sucesso.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir: $e')),
          );
        }
      }
    }
  }

  Future<void> _cancelBolao(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Bolão'),
        content: const Text('Deseja marcar este bolão como Cancelado? O status será alterado para os usuários.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar Cancelamento', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('boloes').doc(id).update({'status': 'Cancelado'});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bolão cancelado com sucesso.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao cancelar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('boloes').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar bolões: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          }

          final boloes = snapshot.data?.docs ?? [];

          if (boloes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_soccer, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Nenhum bolão ativo no momento.', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: boloes.length,
            itemBuilder: (context, index) {
              final doc = boloes[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final name = data['name'] ?? 'Bolão Sem Nome';
              final status = data['status'] ?? 'Aberto';
              final entryFee = data['entryFee']?.toString() ?? '0';
              final category = data['category']?.toString().toUpperCase() ?? 'N/A';
              
              DateTime? matchDate;
              if (data['matchDateTime'] is Timestamp) {
                matchDate = (data['matchDateTime'] as Timestamp).toDate();
              }
              final dateStr = matchDate != null 
                  ? DateFormat('dd/MM/yyyy HH:mm').format(matchDate) 
                  : 'Data indefinida';

              final isCanceled = status == 'Cancelado';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCanceled ? Colors.red.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isCanceled ? Colors.red.shade800 : Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.category, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Categoria: $category', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(width: 16),
                          const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Entrada: R\$ $entryFee', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.event, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text('Jogo: $dateStr', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isCanceled)
                            TextButton.icon(
                              onPressed: () => _cancelBolao(doc.id),
                              icon: const Icon(Icons.block, color: Colors.orange),
                              label: const Text('Cancelar', style: TextStyle(color: Colors.orange)),
                            ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _deleteBolao(doc.id, name),
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Excluir', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
