import typing
import pathlib

from pydantic import ValidationError

from qhub.exception import QHubException
from qhub.schema import QHubConfig


class QHubValidationError(QHubException):
    pass


def parse_pydantic_validation_error(exception):
    return str(exception)


def verify(config_filename : typing.Union[str, pathlib.Path]):
    path = pathlib.Path(config_filename).absolute()

    if not path.is_file():
        raise QHubValidationError(f'QHub configuration filename path "{path}" does not exist')

    try:
        config = QHubConfig.from_file(path)
    except ValidationError as e:
        raise QHubValidationError(f'QHub configuration file path "{path}" has the following schema errors:\n{parse_pydantic_validation_error(e)}')

    return config
