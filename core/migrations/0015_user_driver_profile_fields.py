from django.db import migrations, models


def _driver_fields():
    return [
        (
            'vehicle_image',
            models.ImageField(blank=True, null=True, upload_to='vehicles/'),
        ),
        (
            'vehicle_plate',
            models.CharField(blank=True, max_length=50),
        ),
        (
            'vehicle_type',
            models.CharField(blank=True, max_length=120),
        ),
    ]


def add_missing_driver_fields(apps, schema_editor):
    User = apps.get_model('core', 'User')
    table_name = User._meta.db_table

    with schema_editor.connection.cursor() as cursor:
        existing_columns = {
            column.name
            for column in schema_editor.connection.introspection.get_table_description(
                cursor,
                table_name,
            )
        }

    for field_name, field in _driver_fields():
        if field_name in existing_columns:
            continue

        field.set_attributes_from_name(field_name)
        schema_editor.add_field(User, field)
        existing_columns.add(field_name)


def remove_existing_driver_fields(apps, schema_editor):
    User = apps.get_model('core', 'User')
    table_name = User._meta.db_table

    with schema_editor.connection.cursor() as cursor:
        existing_columns = {
            column.name
            for column in schema_editor.connection.introspection.get_table_description(
                cursor,
                table_name,
            )
        }

    for field_name, _ in reversed(_driver_fields()):
        if field_name not in existing_columns:
            continue

        schema_editor.remove_field(User, User._meta.get_field(field_name))
        existing_columns.remove(field_name)


class Migration(migrations.Migration):

    dependencies = [
        ('core', '0014_orderitem_topup_details'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[
                migrations.RunPython(
                    add_missing_driver_fields,
                    remove_existing_driver_fields,
                ),
            ],
            state_operations=[
                migrations.AddField(
                    model_name='user',
                    name='vehicle_image',
                    field=models.ImageField(blank=True, null=True, upload_to='vehicles/'),
                ),
                migrations.AddField(
                    model_name='user',
                    name='vehicle_plate',
                    field=models.CharField(blank=True, max_length=50),
                ),
                migrations.AddField(
                    model_name='user',
                    name='vehicle_type',
                    field=models.CharField(blank=True, max_length=120),
                ),
            ],
        ),
    ]
