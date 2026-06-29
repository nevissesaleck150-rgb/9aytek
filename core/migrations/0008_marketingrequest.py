from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0007_order_driver_rating_order_is_shares_distributed_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='MarketingRequest',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('status', models.CharField(choices=[('pending', 'En attente'), ('accepted', 'Acceptée'), ('rejected', 'Rejetée')], default='pending', max_length=10)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('influencer', models.ForeignKey(limit_choices_to={'role': 'influencer'}, on_delete=django.db.models.deletion.CASCADE, related_name='marketing_requests_sent', to='core.user')),
                ('product', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='marketing_requests', to='core.product')),
                ('vendor', models.ForeignKey(limit_choices_to={'role': 'vendor'}, on_delete=django.db.models.deletion.CASCADE, related_name='marketing_requests_received', to='core.user')),
            ],
            options={
                'unique_together': {('influencer', 'product')},
            },
        ),
    ]
