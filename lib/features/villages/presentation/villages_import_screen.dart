import 'package:cities_offline_app/features/villages/presentation/bloc/villages_cubit.dart';
import 'package:cities_offline_app/services/localization/translator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VillagesImportScreen extends StatelessWidget {
  const VillagesImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Translator(
          termin: AppGlossary.villagesDbImport,
          builder: (text) => Text(text),
        ),
      ),
      body: BlocBuilder<VillagesCubit, VillagesState>(
        builder: (context, state) {
          if (state.isAvailable) {
            return _InstalledView();
          }
          return _DownloadOrIdleView(state: state);
        },
      ),
    );
  }
}

class _DownloadOrIdleView extends StatelessWidget {
  final VillagesState state;

  const _DownloadOrIdleView({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDownloading = state.status == VillagesStatus.downloading;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(theme, AppGlossary.archiveSize.translate(), '481 MB'),
                const SizedBox(height: 8),
                _infoRow(theme, AppGlossary.installedSize.translate(), '~1.5 GB'),
                const SizedBox(height: 8),
                _infoRow(theme, AppGlossary.requiredFreeSpace.translate(), '≥ 2 GB'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppGlossary.archiveWillBeDeleted.translate(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (isDownloading) ...[
          const SizedBox(height: 24),
          LinearProgressIndicator(value: state.progress),
          const SizedBox(height: 8),
          if (state.progress >= 1)
            Text(
              AppGlossary.unpacking.translate(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            )
          else
            Text(
              '${(state.progress * 481).round()} MB / 481 MB',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(height: 4),
          Text(
            '${(state.progress * 100).toInt()}%',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Center(
            child: OutlinedButton.icon(
              onPressed: () => context.read<VillagesCubit>().cancelDownload(),
              icon: const Icon(Icons.close),
              label: Text(AppGlossary.cancel.translate()),
            ),
          ),
        ],
        if (state.status == VillagesStatus.failed) ...[
          const SizedBox(height: 24),
          Text(
            state.error ?? AppGlossary.importError.translate(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: FilledButton.icon(
              onPressed: () => context.read<VillagesCubit>().startDownload(),
              icon: const Icon(Icons.refresh),
              label: Text(AppGlossary.retry.translate()),
            ),
          ),
        ],
        if (!isDownloading && state.status != VillagesStatus.failed) ...[
          const SizedBox(height: 24),
          Center(
            child: FilledButton.icon(
              onPressed: () => context.read<VillagesCubit>().startDownload(),
              icon: const Icon(Icons.download),
              label: Translator(
                termin: AppGlossary.downloadAndInstall,
                builder: (text) => Text(text),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
        Text(value),
      ],
    );
  }
}

class _InstalledView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 80,
            color: theme.colorScheme.primary,
            fill: 1,
          ),
          const SizedBox(height: 24),
          Translator(
            termin: AppGlossary.importSuccess,
            builder: (text) => Text(
              text,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.read<VillagesCubit>().deleteVillages(),
            icon: const Icon(Icons.delete_forever),
            label: Text(AppGlossary.deleteVillages.translate()),
          ),
        ],
      ),
    );
  }
}
