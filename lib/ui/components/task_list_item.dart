import 'package:flutter/material.dart';
import '../../data/models/maintenance_task.dart';

class TaskListItem extends StatefulWidget {
  final MaintenanceTask task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskListItem({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<TaskListItem> createState() => _TaskListItemState();
}

class _TaskListItemState extends State<TaskListItem>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations optimized for high refresh rate
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOutCubicEmphasized,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOutCubicEmphasized,
    ));

    // Start entrance animation
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.forward();
  }

  void _onTapCancel() {
    _scaleController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
        child: Card(
          elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: widget.onTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      ],
                    ),
                ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task title with smooth text animation
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOutCubicEmphasized,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ) ??
                                const TextStyle(),
                        child: Text(widget.task.title),
                      ),

                      const SizedBox(height: 8),

                      // Task description
                      Text(
                        widget.task.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Action buttons with stagger animation
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (widget.onComplete != null)
                            _AnimatedActionButton(
                              icon: Icons.check_circle_outline,
                              label: 'Complete',
                              color: Colors.green,
                              onPressed: widget.onComplete!,
                              delay: const Duration(milliseconds: 100),
                            ),
                          if (widget.onEdit != null)
                            _AnimatedActionButton(
                              icon: Icons.edit_outlined,
                              label: 'Edit',
                              color: Colors.blue,
                              onPressed: widget.onEdit!,
                              delay: const Duration(milliseconds: 150),
                            ),
                          if (widget.onDelete != null)
                            _AnimatedActionButton(
                              icon: Icons.delete_outline,
                              label: 'Delete',
                              color: Colors.red,
                              onPressed: widget.onDelete!,
                              delay: const Duration(milliseconds: 200),
                        ),
                        ],
                      ),
                    ],
                  ),
                ),
            ),
            ),
          ),
        );
      },
    );
  }
}

class _AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final Duration delay;

  const _AnimatedActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    required this.delay,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubicEmphasized,
    ));

    // Start animation with delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton.icon(
                onPressed: widget.onPressed,
                icon: Icon(widget.icon, size: 18),
                label: Text(widget.label),
                style: TextButton.styleFrom(
                  foregroundColor: widget.color,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
      ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
