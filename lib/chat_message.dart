import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  const ChatMessage({super.key, required this.data, this.mine});

  final Map<String, dynamic> data;
  final bool? mine;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      child: Row(
        children: [
          // Verifica se 'mine' é verdadeiro antes de exibir o avatar
          if (mine != true) // Se 'mine' for nulo ou falso
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                    data['senderPhotoUrl'] ?? ''), // URL de fallback
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: mine == true
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start, // Verifica se 'mine' é verdadeiro
              children: [
                data['imgUrl'] != null
                    ? Image.network(data['imgUrl'])
                    : Text(
                        data['text'] ?? 'Sem mensagem',
                        textAlign: mine == true
                            ? TextAlign.end
                            : TextAlign
                                .start, // Verifica se 'mine' é verdadeiro
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                Text(
                  data['senderName'] ?? 'Desconhecido',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w300,
                  ),
                )
              ],
            ),
          ),
          // Verifica se 'mine' é verdadeiro antes de exibir o avatar
          if (mine == true) // Se 'mine' for verdadeiro
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(data['senderPhotoUrl'] ??
                    'https://example.com/placeholder.png'), // URL de fallback
              ),
            ),
        ],
      ),
    );
  }
}
